module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.View.V1.Model

public inductive NodeKind where
  | Document
  | Main
  | Heading
  | Text
  | Form
  | SignedInt64Input
  | OperationSelect
  | SubmitButton
  | LiveOutput

public inductive InputGrammar where
  | AsciiSignedInt64

public inductive StyleToken where
  | Compact
  | HighContrast
  | SystemSans

public structure SelectOption where
  value : UInt8
  label : String
  requestName : String

public structure Node where
  kind : NodeKind
  identifier : String
  label : String
  grammar : Option (InputGrammar)
  children : List (String)

public structure View where
  title : String
  language : String
  heading : String
  nodes : List (Node)
  options : List (SelectOption)
  inputError : String
  divisionError : String
  overflowError : String
  layout : StyleToken
  color : StyleToken
  typography : StyleToken

end PrismPM.Foundation.View.V1.Model
