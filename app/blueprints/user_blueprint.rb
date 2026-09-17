# frozen_string_literal: true

class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email

  field :role do |user|
    {
      code: user.role,
      label: I18n.t("user.roles.#{user.role}", default: user.role.titleize)
    }
  end

  field :disabled do |user| # rubocop:disable Style/SymbolProc -- Blueprinter yields extra args &:disabled? can't ignore
    user.disabled?
  end
end
