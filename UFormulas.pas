unit UFormulas;
// you to compute the UNESCO International Equation of State (IES 80)
// as described in Fofonoff, JGR, Vol 90 No. C2, pp 3332-3342, March 20, 1985.

interface
uses
  Math, IniFiles, SysUtils;

type
    TParam    = record  // Parametros que se le pasan a la función para calcular salinidad, cond....
                  canal   : integer;                      // Numero del canal donde se saca el valor
                  select  : 0..1;                         // 0=NO, 1=SI
                  valor   : real;                         // Valor del parametro
                  descrip : string;                       // Descripción del parametro  
                end;

    TinfoCalc = record
                  NombreParm    : string;                 // Nombre del Parámetro a Calcular
                  formula       : byte;                   // Codigo de la ecuación a usar
                  Calcular      : 0..1;    //0=NO, 1=SI   // Flag para saber si se debe calcular
                  Nparam        : byte;                   // Cantidad de Parametros Usados
                  NparamNecesa  : byte;                   // Numero de parámetros necesarios
                  CantDecim     : byte;                   // Cantidad de Decimales;
                  Unidad        : string;                 // Unidad del parametro PSU, ºC,....
                  Descripcion   : string;                 // Descripción del parámetro
                  Comentario    : String;                 // Comentario sobre el parámetro     
                  AParam        : array [0..7] of TParam; // Arreglo de Parametros
                  ResultCalcNum : real;                   // Valor del resultado del calculo salinidad, densidad....
                  ResultCalcStr : string;                 // Valor del resultado del calculo pero en String;
                end;


    TCalculoParam = class(Tobject)
    private
      //
    public
      Parametros : array [0..4] of TinfoCalc;
      CantParm   : byte;

      constructor Crear;
      destructor  Destruir;

      procedure InicializarCalculos;
      function  GuardarParametros(NombreINI, NombreSec : string):boolean;
      function  CargarParametros(NombreINI, NombreSec : string):boolean;
      procedure  CalcularValorParam(NParam :byte);

      function presion_profundidad(depth :real):real;
      function CalculoSalinidad(cond,t,depth:real):real;
      function CalculoDesnidad0(sal,t:real):real;
      function CalculoDesnidad(cond,t,depth:real):real;
      function CalculoVelocidadSonido(cond,t,depth:real):real;
      function CalculoCalorEspecifico(cond,t,depth:real):real;
      function CalculoPuntoCongelamiento(cond,t,depth:real):real;
      function CalculoAdiabaticLapseRate(cond,t,depth:real):real;
      function CalculoTemperaturaPotential(cond,t0,depth:real):real;
      function CalculoSensacionTermica(T,V,H:real):real;
      function CalculoConductividadCorregida(cond,t:real):real;
      function adiabaticLapseRate(s,t,p:real):real;
    end;

implementation

////////////////////////////////////////////////////////////////////////////////
//////// TCalculoParam
////////////////////////////////////////////////////////////////////////////////
constructor TCalculoParam.Crear;
begin
  CantParm := length(Parametros);
  InicializarCalculos;
end;

////////////////////////////////////////////////////////////////////////////////
destructor TCalculoParam.Destruir;
begin
//
end;

////////////////////////////////////////////////////////////////////////////////
procedure TCalculoParam.InicializarCalculos;
begin
  // Configuro el calculo de la SALINIDAD
  with Parametros[0] do begin
    NombreParm   := 'Salinidad';
    formula      := 0;
    Calcular     := 0; //0=NO, 1=SI
    Nparam       := 3;
    NparamNecesa := 2;
    CantDecim    := 1;
    Unidad       := 'PSU';
    Descripcion  := 'Salinidad';
    Comentario   := 'Nota:'+#13#10#13#10+'Para calcular la SALINIDAD se requiere como parámetros de entrada, la'
                     + ' conductividad [mS/cm], la temperatura [ºC] y la profundiad [m] (opcional para mejor presición).';
    // Conductividad
    AParam[0].canal := -1; AParam[0].select := 0; AParam[0].valor := 0; AParam[0].descrip := 'Conductividad [mS/cm]';
    // Temperatura
    AParam[1].canal := -1; AParam[1].select := 0; AParam[1].valor := 0; AParam[1].descrip := 'Temperatura [ºC]';
    // Profundidad
    AParam[2].canal := -1; AParam[2].select := 0; AParam[2].valor := 0; AParam[2].descrip := 'Profundidad [m] (opcional)';
  end;

  // Configuro el calculo de la DENSIDAD
  with Parametros[1] do begin
    NombreParm   := 'Densidad';
    formula      := 1;
    Calcular     := 0; //0=NO, 1=SI
    Nparam       := 3;
    NparamNecesa := 2;
    CantDecim    := 2;
    Unidad       := 'kg/m^3';
    Descripcion  := 'Densidad';
    Comentario   := 'Nota:'+#13#10#13#10+'Para calcular la DENSIDAD se requiere como parámetros de entrada, la'
                     + ' conductividad [mS/cm], la temperatura [ºC] y la profundiad [m] (opcional para mejor presición).';
    // Conductividad
    AParam[0].canal := -1; AParam[0].select := 0; AParam[0].valor := 0; AParam[0].descrip := 'Conductividad [mS/cm]';
    // Temperatura
    AParam[1].canal := -1; AParam[1].select := 0; AParam[1].valor := 0; AParam[1].descrip := 'Temperatura [ºC]';
    // Profundidad
    AParam[2].canal := -1; AParam[2].select := 0; AParam[2].valor := 0; AParam[2].descrip := 'Profundidad [m] (opcional)';
  end;

  // Configuro el calculo de la VELOCIDAD DEL SONIDO
  with Parametros[2] do begin
    NombreParm   := 'VelocidadSonido';
    formula      := 2;
    Calcular     := 0; //0=NO, 1=SI
    Nparam       := 3;
    NparamNecesa := 2;
    CantDecim    := 1;
    Unidad       := 'm/s';
    Descripcion  := 'Velocidad del Sonido';
    Comentario   := 'Nota:'+#13#10#13#10+'Para calcular la VELOCIDAD DEL SONIDO se requiere como parámetros de entrada, la'
                     + ' conductividad [mS/cm], la temperatura [ºC] y la profundiad [m] (opcional para mejor presición).';
    // Conductividad
    AParam[0].canal := -1; AParam[0].select := 0; AParam[0].valor := 0; AParam[0].descrip := 'Conductividad [mS/cm]';
    // Temperatura
    AParam[1].canal := -1; AParam[1].select := 0; AParam[1].valor := 0; AParam[1].descrip := 'Temperatura [ºC]';
    // Profundidad
    AParam[2].canal := -1; AParam[2].select := 0; AParam[2].valor := 0; AParam[2].descrip := 'Profundidad [m] (opcional)';
  end;

  // Configuro el calculo de la SENSACIÓN TÉRMICA
  with Parametros[3] do begin
    NombreParm   := 'SensacionTermica';
    formula      := 3;
    Calcular     := 0; //0=NO, 1=SI
    Nparam       := 3;
    NparamNecesa := 3;
    CantDecim    := 1;
    Unidad       := 'ºC';
    Descripcion  := 'Sensación Térmica';
    Comentario   := 'Nota:'+#13#10#13#10+'Para calcular la SENSACIÓN TÉRMICA se requiere como parámetros de entrada, la'
                     + ' temperatura [ºC], la velocidad del viento [km/h] y la humedad relativa [%].';
    // Temperatura
    AParam[0].canal := -1; AParam[0].select := 0; AParam[0].valor := 0; AParam[0].descrip := 'Temperatura [ºC]';
    // Velocidad Viento
    AParam[1].canal := -1; AParam[1].select := 0; AParam[1].valor := 0; AParam[1].descrip := 'Velocidad del Viento [km/h]';
    // Humedad
    AParam[2].canal := -1; AParam[2].select := 0; AParam[2].valor := 0; AParam[2].descrip := 'Humedad [%]';
  end;

  // Configuro el calculo de la Conductividad Corregida 20ºC
  with Parametros[4] do begin
    NombreParm   := 'ConducCorreg';
    formula      := 4;
    Calcular     := 0; //0=NO, 1=SI
    Nparam       := 2;
    NparamNecesa := 2;
    CantDecim    := 2;
    Unidad       := 'mS';
    Descripcion  := 'Conductividad Corregida a 20ºC';
    Comentario   := 'Nota:'+#13#10#13#10+'Para calcular la CONDUCTIVIDAD CORREGIDA a 20ºC se requiere como parámetros '
                     + 'de entrada, la Conductividad  y temperatura [ºC].';
    // Conductividad
    AParam[0].canal := -1; AParam[0].select := 0; AParam[0].valor := 0; AParam[0].descrip := 'Conductividad';

    // Temperatura
    AParam[1].canal := -1; AParam[1].select := 0; AParam[1].valor := 0; AParam[1].descrip := 'Temperatura [ºC]';
  end;

end;

////////////////////////////////////////////////////////////////////////////////
function TCalculoParam.GuardarParametros(NombreINI, NombreSec : string):boolean;
var
  ArchivoINI   : TIniFile;
  i,j          : byte;

begin
  ArchivoINI   := TIniFile.Create(NombreINI);

  // Me aseguro que este el equipo en el Archivo INI
  if not ArchivoINI.SectionExists(NombreSec) then begin
    ArchivoINI.Free;
    result := false;
    exit;
  end;

  // Guardo los datos en el Archivo INI
  try
    for i:=0 to length(Parametros)-1 do begin
      with Parametros[i] do begin
        //ArchivoINI.WriteString(NombreSec, NombreParm + '_formula' ,  intToStr(formula));
        ArchivoINI.WriteString(NombreSec, NombreParm + '_Calcular',  intToStr(Calcular));
        //ArchivoINI.WriteString(NombreSec, NombreParm + '_Nparam'  ,  intToStr(Nparam));
        for j:=0 to length(AParam)-1 do begin
          ArchivoINI.WriteString(NombreSec, NombreParm + '_Aparam'+intToStr(j)+'Canal' , intToStr(AParam[j].canal));
          ArchivoINI.WriteString(NombreSec, NombreParm + '_Aparam'+intToStr(j)+'Select', intToStr(AParam[j].select));
        end;
      end;
    end;
  except
    ArchivoINI.Free;
    result := false;
    exit;
  end;

  ArchivoINI.Free;
  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
function TCalculoParam.CargarParametros(NombreINI, NombreSec : string):boolean;
var
  ArchivoINI   : TIniFile;
  i,j          : byte;

begin
  ArchivoINI   := TIniFile.Create(NombreINI);

  // Me aseguro que este el equipo en el Archivo INI
  if not ArchivoINI.SectionExists(NombreSec) then begin
    ArchivoINI.Free;
    result := false;
    exit;
  end;

  // Cargo los datos desde el Archivo INI
  try
    for i:=0 to length(Parametros)-1 do begin
      with Parametros[i] do begin
        //formula  := StrToInt(ArchivoINI.ReadString(NombreSec, NombreParm + '_formula', IntToStr(i)));
        Calcular := StrToInt(ArchivoINI.ReadString(NombreSec, NombreParm + '_Calcular', '0'));
        //Nparam   := StrToInt(ArchivoINI.ReadString(NombreSec, NombreParm + '_Nparam', '0'));

        for j:=0 to length(AParam)-1 do begin
          AParam[j].canal  := StrToInt(ArchivoINI.ReadString(NombreSec, NombreParm +'_Aparam'+intToStr(j)+'Canal' , '-1'));
          AParam[j].select := StrToInt(ArchivoINI.ReadString(NombreSec, NombreParm +'_Aparam'+intToStr(j)+'Select', '0'));
        end;
      end;
    end;
  except
    ArchivoINI.Free;
    result := false;
    exit;
  end;

  ArchivoINI.Free;
  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TCalculoParam.CalcularValorParam(NParam :byte);
var
  auxDecimales : string;
  i            : byte; 

begin
  // Si no se tiene que calcular salgo
  if Parametros[NParam].Calcular <> 1 then  begin
    Parametros[NParam].ResultCalcNum := 0;
    Parametros[NParam].ResultCalcStr := 'ERROR';
    exit;
  end;

  with Parametros[NParam] do begin
    // Genero el string para el formatFloat osea la cant de decimales deseados
    auxDecimales :='0';
    if CantDecim > 0 then begin
      auxDecimales :='0.';
      for i:=1 to CantDecim do auxDecimales := auxDecimales + '0';
    end;

    case formula of
      // Cálculo la salinidad
      0 : begin
            ResultCalcNum := CalculoSalinidad(AParam[0].valor, AParam[1].valor, AParam[2].valor);
            if (ResultCalcNum <> -9999) then ResultCalcStr := FormatFloat(auxDecimales,ResultCalcNum)
            else ResultCalcStr := 'ERROR';
           end;

      // Cálculo la Densidad
      1 : begin
            ResultCalcNum := CalculoDesnidad(AParam[0].valor, AParam[1].valor, AParam[2].valor);
            if (ResultCalcNum <> -9999) then ResultCalcStr := FormatFloat(auxDecimales,ResultCalcNum)
            else ResultCalcStr := 'ERROR';
           end;

      // Cálculo la Velocidad del Sonido
      2 : begin
            ResultCalcNum := CalculoVelocidadSonido(AParam[0].valor, AParam[1].valor, AParam[2].valor);
            if (ResultCalcNum <> -9999) then ResultCalcStr := FormatFloat(auxDecimales,ResultCalcNum)
            else ResultCalcStr := 'ERROR';
           end;

      // Cálculo la Sensación Térmica
      3 : begin
            ResultCalcNum := CalculoSensacionTermica(AParam[0].valor, AParam[1].valor, AParam[2].valor);
            if (ResultCalcNum <> -9999) then ResultCalcStr := FormatFloat(auxDecimales,ResultCalcNum)
            else ResultCalcStr := 'ERROR';
          end;

      // Cálculo la Conductividad Corregida
      4 : begin
            ResultCalcNum := CalculoConductividadCorregida(AParam[0].valor, AParam[1].valor);
            if (ResultCalcNum <> -9999) then ResultCalcStr := FormatFloat(auxDecimales,ResultCalcNum)
            else ResultCalcStr := 'ERROR';
          end;

    else
      ResultCalcNum := 0;
      ResultCalcStr := 'ERROR';
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Calculo de la presión en función de la Profundidad (m)
function TCalculoParam.presion_profundidad(depth :real):real;
var
  slat, c1, c2, p : real;

begin
  try
  	slat   := sin(30*3.14159265/180.0);
	  c1     := 5.92e-3 + 5.25e-3 * slat * slat;
	  c2     := 2.21e-6;
  	p      := ((1-c1)- sqrt((1-c1)*(1-c1)-4*c2*depth)) / (2*c2);
    
	  result := p;
  except
    result := -9999;
  end;

end;

////////////////////////////////////////////////////////////////////////////////
// Compute salinity (psu) from conductivity (mS/cm), temperature and pressure
function TCalculoParam.CalculoSalinidad(cond,t,depth :real):real;
var
  R, rrt, Rp, Rt, A, B, C, sal, Rt5, t15, dels, p : real;

begin
  try
    p    := presion_profundidad(depth);

	  R    := cond / 42.9140;
  	rrt  := 0.6766097 + t * ( 0.0200564 + t * ( 1.104259e-04 + t * ( -6.9698e-07 + t * 1.0031e-09 ) ) );
	  A    := 0.4215 - 0.003107 * t;
  	B    := 1 + t * ( 0.03426 + t * 0.0004464 );
	  C    := p * ( 2.07e-5 + p * ( -6.37e-10 + p * 3.989e-15 ) );
  	Rp   := 1 + C / ( B + A * R );
	  Rt   := R / rrt / Rp;

  	Rt5  := sqrt( Rt );
  	t15  := t - 15;
	  dels := t15 / ( 1 + 0.0162 * t15 );
  	sal  :=  ( 14.0941 + dels * -0.0375 ) + Rt5 * ( ( -7.0261 + dels *  0.0636 ) + Rt5 * ( (  2.7081 + dels *  -0.0144 ) ) );
	  sal  := ( 0.008 + dels * 0.0005 ) + Rt5 * ( ( -0.1692 + dels * -0.0056 )	+ Rt5 * ( ( 25.3851 + dels * -0.0066 )	+ Rt5 * sal ) );

  	result := sal;
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Compute conductivity (mS/cm) at 20ºC
function TCalculoParam.CalculoConductividadCorregida(cond , t : real):real;
var
  Fac  : real;

begin
  try
    Fac := -0.0000183*t*t*t + 0.0015496*t*t - 0.0618885*t + 1.7646297;

  	result := cond*Fac;
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Compute density at the surface from salinity (PSU) and temperature
function TCalculoParam.CalculoDesnidad0(sal,t :real):real;
var
  A, B, C, D, dens0 :real;

begin
  try
  	A      := 1.001685e-04 + t * ( -1.120083e-06 + t * 6.536332e-09 );
	  A      := 999.842594 + t * (  6.793952e-02 + t * ( -9.095290e-03 + t * A ) );
  	B      := 7.6438e-05 + t * ( -8.2467e-07 + t * 5.3875e-09 );
	  B      := 0.824493 + t * ( -4.0899e-03 + t * B );
  	C      := -5.72466e-03 + t * ( 1.0227e-04 - t * 1.6546e-06 );
	  D      := 4.8314e-04;
  	dens0  := A + sal * (  B + C * sqrt(sal) + D * sal );

	  result := dens0;
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Compute density from conductivity (mS/cm), temperature and depth
function TCalculoParam.CalculoDesnidad(cond,t,depth :real):real;
var
  d0, d, K, E, F, G, H, I, J, M, N, t2, t3, t4, s1p5, pb, sal, p : real;

begin
  try
  	t2  := t * t;
	  t3  := t2 * t;
  	t4  := t3 * t;

    p   := presion_profundidad(depth);
    sal := CalculoSalinidad(cond,t,depth);
	  d0  := CalculoDesnidad0(sal,t);
  	E   := 19652.21 + 148.4206 * t - 2.327105 * t2 + 1.360477e-2 * t3 - 5.155288e-5 * t4;
	  F   := 54.6746 - 0.603459 * t + 1.09987e-2 * t2 - 6.1670e-5 * t3;
  	G   := 7.944e-2 + 1.6483e-2 * t - 5.3009e-4 * t2;
	  H   := 3.239908 + 1.43713e-3 * t + 1.16092e-4 * t2 - 5.77905e-7 * t3;
  	I   := 2.2838e-3 - 1.0981e-5 * t - 1.6078e-6 * t2;
	  J   := 1.91075e-4;
  	M   := 8.50935e-5 - 6.12293e-6 * t + 5.2787e-8 * t2;
	  N   := -9.9348e-7 + 2.0816e-8 * t + 9.1697e-10 * t2;

  	s1p5 := sal * sqrt(sal);

	  pb := p/10;

  	K := (E + F*sal + G*s1p5) + (H + I*sal + J*s1p5) * pb + (M + N*sal) * pb * pb;
	  d := d0 / (1 - pb/K);

  	result := d;
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Compute speed of sound (m/s) from conductivity (mS/cm), temperature (deg C) and depth (m)
function TCalculoParam.CalculoVelocidadSonido(cond,t,depth :real):real;
var
  sr, D, b1, b0, B, a3, a2, a1, a0, A, c3, c2, c1, c0, C, p, sal :real;

begin
  try
    p   := presion_profundidad(depth);
    sal := CalculoSalinidad(cond,t,depth);

  	sr := sqrt(sal);
	  D  := 1.727e-3 - 7.9836e-6 * p;
  	b1 := 7.3637e-5 + 1.7945e-7 * t;
	  b0 := -1.922e-2 - 4.42e-5 * t;
  	B  := b0 + b1 * p;
	  a3 := (-3.389e-13 * t + 6.649e-12) * t + 1.100e-10;
  	a2 := ((7.988e-12 * t - 1.6002e-10) * t + 9.1041e-9) * t - 3.9064e-7;
	  a1 := (((-2.0122e-10 * t + 1.0507e-8) * t - 6.4885e-8) * t - 1.2580e-5) * t + 9.4742e-5;
  	a0 := (((-3.21e-8 * t + 2.006e-6) * t + 7.164e-5) * t -1.262e-2) * t + 1.389;
	  A  := ((a3 * p + a2) * p + a1) * p + a0;
  	c3 := (-2.3643e-12 * t + 3.8504e-10) * t - 9.7729e-9;
	  c2 := (((1.0405e-12 * t -2.5335e-10) * t + 2.5974e-8) * t - 1.7107e-6) * t + 3.1260e-5;
  	c1 := (((-6.1185e-10 * t + 1.3621e-7) * t - 8.1788e-6) * t + 6.8982e-4) * t + 0.153563;
	  c0 := ((((3.1464e-9 * t - 1.47800e-6) * t + 3.3420e-4) * t - 5.80852e-2) * t + 5.03711) * t + 1402.388;
  	C  := ((c3 * p + c2) * p + c1) * p + c0;

	  result := (C + (A + B * sr + D * sal) * sal);
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Compute specific heat (J/kg/deg C) from salinity (psu), temperature (deg C) and pressure (bar)
function TCalculoParam.CalculoCalorEspecifico(cond,t,depth:real):real;
var
  sr, a, b, c, cp0, cp1, cp2, cpsw, p, sal :real;

begin
  try
    p   := presion_profundidad(depth);
    sal := CalculoSalinidad(cond,t,depth);

  	sr   := sqrt(sal);
	  // specific heat cp0 for p=0
  	a    := (-1.38385e-3 * t + 0.1072763 ) * t - 7.643575;
	  b    := (5.148e-5 * t - 4.07718e-3) * t + 0.1770383;
  	c    := (((2.093236e-5 * t - 2.654387e-3) * t + 0.1412855) * t - 3.720283) * t + 4217.4;
	  cp0  := (b*sr+a)*sal+c;
  	// cp1 pressure and temperature terms for s=0
	  a    := (((1.7168e-8 * t + 2.0357e-6) * t - 3.13885e-4) * t + 1.45747e-2) * t - 0.49592;
  	b    := (((2.2956e-11 * t - 4.0027e-9) * t + 2.87533e-7) * t - 1.08645e-5) * t + 2.4931e-4;
	  c    := ((6.136e-13 * t - 6.5637e-11) * t + 2.6380e-9) * t - 5.422e-8;
  	cp1  := ((c*p+b)*p+a)*p;
	  // cp2 pressure and temperature terms for s > 0
  	a    := (((-2.9179e-10 * t + 2.5941e-8) * t + 9.802e-7) * t - 1.28315e-4) * t + 4.9247e-3;
	  b    := (3.122e-8 * t - 1.517e-6) * t - 1.2331e-4;
  	a    := (a+b*sr)*sal;
	  b    := ((1.8448e-11 * t - 2.3905e-9) * t + 1.17054e-7) * t - 2.9558e-6;
  	b    := (b + 9.971e-8 * sr) * sal;
	  c    := (3.513e-13 * t - 1.7682e-11) * t + 5.540e-10;
  	c    := (c - 1.4300e-12 * t * sr) * sal;
	  cp2  := ((c*p+b)*p+a)*p;
  	cpsw := cp0 + cp1 + cp2;

	  result := cpsw;
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TCalculoParam.CalculoPuntoCongelamiento(cond,t,depth:real):real;
var
  tf, sr, p, sal : real;

begin
  p   := presion_profundidad(depth);
  sal := CalculoSalinidad(cond,t,depth);
	sr  := sqrt(sal);
	tf  := (-0.0575 + 1.710523e-3 * sr - 2.154996e-4 * sal) * sal - 7.53e-4 * p;

	result := tf;
end;

////////////////////////////////////////////////////////////////////////////////
// Compute adiabatic lapse rate (deg C/dBar) from conductivity (mS/cm), temperature (deg C) and depth (m)
function TCalculoParam.CalculoAdiabaticLapseRate(cond,t,depth:real):real;
var
  ds, atg, p, sal :real;

begin
  try
    p   := presion_profundidad(depth);
    sal := CalculoSalinidad(cond,t,depth);

  	ds  := sal - 35.0;
	  atg := ((-2.1687e-16 * t + 1.8676e-14) * t - 4.6206e-13) * p * p;
  	atg := atg + (2.7759e-12 * t - 1.1351e-10 ) * ds * p;
	  atg := atg + (((-5.4481e-14 * t + 8.7330e-12) * t - 6.7795e-10) * t + 1.8741e-8) * p;
  	atg := atg + (-4.2393e-8 * t + 1.8932e-6 ) * ds;
	  atg := atg + ((6.6228e-10 * t - 6.8360e-8) * t + 8.5258e-6) * t + 3.5803e-5;

	  result := atg*1000;
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TCalculoParam.adiabaticLapseRate(s,t,p:real):real;
var
  ds, atg : real;

begin
  try
  	ds  := s - 35.0;
	  atg := ((-2.1687e-16 * t + 1.8676e-14) * t - 4.6206e-13) * p * p;
  	atg := atg + (2.7759e-12 * t - 1.1351e-10 ) * ds * p;
	  atg := atg + (((-5.4481e-14 * t + 8.7330e-12) * t - 6.7795e-10) * t + 1.8741e-8) * p;
  	atg := atg + (-4.2393e-8 * t + 1.8932e-6 ) * ds;
	  atg := atg + ((6.6228e-10 * t - 6.8360e-8) * t + 8.5258e-6) * t + 3.5803e-5;

  	result := atg;
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Compute potential temperature (deg C) from conductivity (mS/cm), temperature (deg C) and depth (m)
function TCalculoParam.CalculoTemperaturaPotential(cond,t0,depth:real):real;
var
  p, t, h, xk, q, theta, s, p0 : real;

begin
  try
    p0    := presion_profundidad(depth);
    s     := CalculoSalinidad(cond,t0,depth);

  	p     := p0;
	  t     := t0;
  	h     := 0 - p;
	  xk    := h * adiabaticLapseRate(s,t,p);
  	t     := t + 0.5 * xk;
	  q     := xk;
	  p     := p + 0.5 * h;
	  xk    := h * adiabaticLapseRate(s,t,p);
	  t     := t + 0.29289322 *(xk-q);
	  q     := 0.58578644 * xk + 0.121320344 * q;
	  xk    := h * adiabaticLapseRate(s,t,p);
	  t     := t + 1.707106781 *(xk-q);
	  q     := 3.414213562 * xk - 4.121320344 * q;
	  p     := p + 0.5 * h;
	  xk    := h * adiabaticLapseRate(s,t,p);
	  theta := t + (xk-2.0*q)/6.0;

	  result := theta;
  except
    result := -9999;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sensación térmica en función de la Temperatura (ºC), Humedad (%) y Velocidad del Viento(km/h)
function TCalculoParam.CalculoSensacionTermica(T,V,H:real):real;
var
  e, HM, WC : real;

begin
  try
    //Humidex
    e  := 6.112*power(10,7.5*T/(237.7+T))*H/100;
    HM := t + 5/9 * (e-10);

    //Winchill
    WC := 13.12 + 0.6215*T - 11.37*power(V,0.16) + 0.3965*T*power(V,0.16);

    result := t;
    if (t<20) then result := WC; // Winchill
    if (t>25) then result := HM; // Humidex
  except
    result := -9999;
  end;

end;

////////////////////////////////////////////////////////////////////////////////
end.

