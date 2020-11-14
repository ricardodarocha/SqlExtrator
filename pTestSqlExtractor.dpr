<<<<<<< HEAD
program pTestSqlExtractor;

uses
  Vcl.Forms,
  Test.SqlExtractor in 'Test.SqlExtractor.pas' {formTestSqlExtractor},
  Assis.SQLExtractor in 'Assis.SQLExtractor.pas',
  Assis.RttiInterceptor in '..\RttiInterceptor\Assis.RttiInterceptor.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  ReportMemoryLeaksOnShutdown := True;
  Application.CreateForm(TformTestSqlExtractor, formTestSqlExtractor);
  Application.Run;
end.
=======
program pTestSqlExtractor;

uses
  Vcl.Forms,
  Test.SqlExtractor in 'Test.SqlExtractor.pas' {formTestSqlExtractor},
  Assis.SQLExtractor in 'Assis.SQLExtractor.pas',
  Assis.RttiInterceptor in '..\RttiInterceptor\Assis.RttiInterceptor.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  ReportMemoryLeaksOnShutdown := True;
  Application.CreateForm(TformTestSqlExtractor, formTestSqlExtractor);
  Application.Run;
end.
>>>>>>> cc2479522c9e0f829b9db0bc5d95c0b7a3a74e48
