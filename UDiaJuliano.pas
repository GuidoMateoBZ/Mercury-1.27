unit UDiaJuliano;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

  function  DiaJuliano(fecha:TDateTime):Double;            {Monday, January 1, 4713 BC}
  function  DiaJulianoModificado(fecha:TDateTime):Double;  {midnight at the beginning of Wednesday November 17, 1858}
  function  DiaJulianoReducido(fecha:TDateTime):Double;    {Tuesday November 16, 1858}
  function  DiaJulianoTruncado(fecha:TDateTime):Double;    {at midnight UT at the beginning of May 24, 1968. It is defined by NASA}
  function  DiaJulianoExcel(fecha:TDateTime):Double;       {Mismo formato que usa el Excel. 01/01/1900 12:00a.m.}

implementation
////////////////////////////////////////////////////////////////////////////////
function  DiaJuliano(fecha:TDateTime):Double;
begin
  {Monday, January 1, 4713 BC}
  result := fecha + 15018 + 2400000.5;
end;

////////////////////////////////////////////////////////////////////////////////
function  DiaJulianoModificado(fecha:TDateTime):Double;
begin
  {midnight at the beginning of Wednesday November 17, 1858}
  result := fecha + 15018;
end;

////////////////////////////////////////////////////////////////////////////////
function  DiaJulianoReducido(fecha:TDateTime):Double;
begin
  {Tuesday November 16, 1858}
  result := fecha + 15018.5
end;

////////////////////////////////////////////////////////////////////////////////
function  DiaJulianoTruncado(fecha:TDateTime):Double;
begin
  {at midnight UT at the beginning of May 24, 1968. It is defined by NASA}
  result := fecha - 24982;
end;

////////////////////////////////////////////////////////////////////////////////
function  DiaJulianoExcel(fecha:TDateTime):Double;
begin
  {Mismo formato que usa el Excel. 01/01/1900 12:00a.m.}
  result := fecha;  //-39172.36782;
end;

////////////////////////////////////////////////////////////////////////////////
end.


