defmodule Repro.Docs do
  use Ash.Domain, otp_app: :repro

  resources do
    resource Repro.Docs.User
    resource Repro.Docs.Doc
    resource Repro.Docs.Doc.Version
  end
end
