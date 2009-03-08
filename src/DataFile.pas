{
 * class for from manualy editing protected .dat file used to store uniform data
 * Copyright (C) 2008  Jan Dušek <GhostJO@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

{
  * SPECIFIKACE FORMATU *
  halvièka(header) celkem 14 byte
    0..1 byte - specifické id této implementace .dat souboru
    2..3 byte - pocet zaznamu v dat souboru
    4..5 byte - velikost v bytech jednoho záznamu
    6..13 byte - cas posledniho zaznamu do souboru

  tìlo souboru
    obsahuje data o velikosti (pocetZaznamu * velikostZaznamu) byte
}

unit DataFile;

interface

uses
  Classes,
  Windows,
  Messages,
  SysUtils,
  Defines;

type
  // hlavicka dat souboru
  // btw. packed znamena ze se polozky nebudou v pameti zarovnavat
  // ale zustanou tak jak sou tj. sizeof(TDataFileHeader) bude 14 a ne 16 nebo na kolik by se to zarovnalo
  TDataFileHeader = packed record
    ID:uint16;                      // unikatni ID teto implementace .dat souborù musi byt 531(ord('Z')+ord('y')+ord('c')+ord('o')+ord('n') = 531 xDDDD )
    RecordsCount:uint16;            // pocet zaznamu v dat souboru
    SizeOfRecord:uint16;            // velikost v bytech jednoho zaznamu

    { cas posledniho zapisu do souboru pomoci tohoto algoritmu,
    pokud se skutecny cas posledniho zapisu souboru nebude rovnat
    s timto znamena to ze se souborem bylo manipulovano }
    LastWriteTime:FILETIME;
  end;

  // definice vlastnich uzivatelskych vyjimek dedicich z Exception z VCL
  EInvalidFile = class(Exception)
  end;

  EFileManualyEdited = class(Exception)
  end;

  EFileCreateError = class(Exception)
  end;

  // samotna trida dat souboru
  TDataFile = class
  private
    m_FileName:string;

    m_Header:TDataFileHeader;
  public
    property RecordsCount:uint16 read m_Header.RecordsCount;
    property SizeOfRecord:uint16 read m_Header.SizeOfRecord;
    property FileName:string read m_FileName;
    constructor Create(const FileName:string);           // konstruktor
    procedure WriteData(ItemsCount, ItemSize:uint16; const Data:pointer);   // zapisuje data
    procedure ReadData(Data:pointer);        // cte data vysledek vyhazuje pres parametr
  end;

implementation

constructor TDataFile.Create(const FileName:string);
var
  DataFile:TFileStream;
  SysTime:SYSTEMTIME;
  FiTime:FILETIME;
  WritedBytes, ReadedBytes:int32;
begin
  m_FileName := FileName;                     // do clenske promene jmena souboru parametr

  if not FileExists(m_FileName) then          // kdyz dany soubor neexistuje
  begin
    // vytvorime soubor pomoci TFileStream z VCL
    DataFile := TFileStream.Create(m_FileName, fmCreate or fmShareDenyWrite);

    // nastavime pocatecni hodnoty hlavicky
    m_Header.ID := 531;
    m_Header.RecordsCount := 0;
    m_Header.SizeOfRecord := 0;

    GetSystemTime(SysTime);      // ziska systemovy cas
    SystemTimeToFileTime(SysTime, FiTime);       // ze systemoveho casu udelame souborovy cas
    m_Header.LastWriteTime := FiTime;            // ulozime do hlavicky

    WritedBytes := DataFile.Write(m_Header, sizeof(m_Header));      // zapisujeme hlavicku
    if WritedBytes <> sizeof(m_Header) then            // kdyz jsme nezapsali pozadovany pocet bajtu
    begin
      DataFile.Free();                                 // uvolnime soubor
      raise EFileCreateError.Create(Format('Failed creating %s', [m_FileName]));     // vyhodime vyjimku
      exit;          // konec (asi nemusi byt ale pro jistotu)
    end;

    // zmenime atribut souboru na disku jelikoz od ziskani systemoveho casu do skutecneho zapisu uplynul nejaky cas
    SetFileTime(DataFile.Handle, nil, nil, @FiTime);

    DataFile.Free();   // uvolnujeme soubor
  end
  else                 // kdyz uz soubor existuje
  begin
    DataFile := TFileStream.Create(m_FileName, fmOpenRead or fmShareDenyWrite);   // otevreme ho ke cteni
    ReadedBytes := DataFile.Read(m_Header, sizeof(m_Header));             // cteme ho data ulozime do m_Header
    if ReadedBytes <> sizeof(m_Header) then           // pokud jsme neprecetli pozadovany pocet bajtu
    begin
      DataFile.Free();                                // uvolnime soubor
      raise EFileCreateError.Create(Format('Failed creating %s', [m_FileName]));   // vyhodime vyjimku
      exit;           // konec (asi nemusi byt ale pro jistotu)
    end;

    if m_Header.ID <> 531 then              // kdyz ID neni 531 tak toto neni validni dat soubor
    begin
      DataFile.Free();                      // uvolnime soubor
      raise EInvalidFile.Create(Format('%s is not valid *.dat file', [m_FileName]));   // vyhodime vyjimku
      exit;               // konec (asi nemusi byt ale pro jistotu)
    end;

    // kdyz skutecna velikost dat souboru neni tak jak ma byt
    if DataFile.Size <> sizeof(TDataFileHeader) + m_Header.RecordsCount * m_Header.SizeOfRecord then
    begin
      DataFile.Free();           // uvolnime soubor
      raise EInvalidFile.Create(Format('%s is not valid *.dat file', [m_FileName]));  // vyhodime vyjimku
      exit;                // konec (asi nemusi byt ale pro jistotu)
    end;

    GetFileTime(DataFile.Handle, nil, nil, @FiTime);        // ziskame skutecny cas posledniho zapisu do souboru
    if int64(m_Header.LastWriteTime) <> int64(FiTime) then    // kdyz skutecny cas a ulozeny cas nejsou stejne -> se souborem nekdo manipuloval
    begin
      DataFile.Free();                                      // uvolnime soubor
      raise EFileManualyEdited.Create(Format('%s was manualy edited', [m_FileName]));  // vyhodime vyjimku
      exit;                   // konec (asi nemusi byt ale pro jistotu)
    end;

    DataFile.Free();        // uvolnime soubor
  end;
end;

procedure TDataFile.WriteData(ItemsCount, ItemSize:uint16; const Data:pointer);
var
  DataFile:TFileStream;
  SysTime:SYSTEMTIME;
  FiTime:FILETIME;
  WritedBytes:int32;
begin
  DataFile := TFileStream.Create(m_FileName, fmOpenWrite or fmShareDenyWrite); // otevirame soubor k zapisu

  // nastavime promenou hlavicky
  m_Header.ID := 531;
  m_Header.RecordsCount := ItemsCount;
  m_Header.SizeOfRecord := ItemSize;

  GetSystemTime(SysTime);           // ziska systemovy cas
  SystemTimeToFileTime(SysTime, FiTime);   // prevede ho na souborovy
  m_Header.LastWriteTime := FiTime;        // ulozi ho do hlavicky

  WritedBytes := DataFile.Write(m_Header, sizeof(m_Header));      // zapiseme hlavicku
  if WritedBytes <> sizeof(m_Header) then          // kdyz jsme nezapsali pozadovany pocet bajtu
  begin
    DataFile.Free();                               // uvolnime soubor
    raise EWriteError.Create(Format('Failed writing to %s', [m_FileName]));      // vyhodime vyjimku
    exit;             // konec (asi nemusi byt ale pro jistotu)
  end;

  WritedBytes := DataFile.Write(Data^, ItemsCount * ItemSize);   // zapiseme data
  if WritedBytes <> (ItemsCount * ItemSize) then            // kdyz jsme nezapsali pozadovany pocet bajtu
  begin
    DataFile.Free();                         // uvolnime soubor          // vyhodime vyjimku
    raise EWriteError.Create(Format('Failed writing to %s', [m_FileName]));
    exit;              // konec (asi nemusi byt ale pro jistotu)
  end;

  // zmenime atribut souboru na disku jelikoz od ziskani systemoveho casu do skutecneho zapisu uplynul nejaky cas
  SetFileTime(DataFile.Handle, nil, nil, @FiTime);         

  DataFile.Free();           // uvolnime soubor
end;

procedure TDataFile.ReadData(Data:pointer);
var
  DataFile:TFileStream;
  ReadedBytes, Count:int32;
begin
  DataFile := TFileStream.Create(m_FileName, fmOpenRead or fmShareDenyWrite);   // otevreme soubor ke cteni
  DataFile.Seek(sizeof(TDataFileHeader), soFromBeginning);     // posun na souboru o hlavicku
  Count := m_Header.RecordsCount * m_Header.SizeOfRecord;      // vypocteme kolik mame precist bajtu z hlavicky
  ReadedBytes := DataFile.Read(Data^, Count);                  // cteme ukladame do parametru
  if ReadedBytes <> Count then            // kdyz jsme neprecetli tolik bajtu kolik jsme chteli
  begin
    DataFile.Free();                     // uvolnime soubor
    raise EReadError.Create(Format('Failed reading %s', [m_FileName]));  // vyhodime vyjimku
    exit;              // konec (asi nemusi byt ale pro jistotu)
  end;
  DataFile.Free();       // uvolnime soubor
end;

end.
