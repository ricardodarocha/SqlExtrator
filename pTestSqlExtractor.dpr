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
  Application.CreateForm(TformTestSqlExtractor, formTestSqlExtractor);
  Application.Run;
end.
