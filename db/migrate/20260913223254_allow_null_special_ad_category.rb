# Permite NULL para distinguir "não informado" (aplica o default do projeto)
# de "explicitamente NONE" (o usuário decidiu não usar categoria especial).
class AllowNullSpecialAdCategory < ActiveRecord::Migration[8.1]
  def change
    change_column_null :ad_campaigns, :special_ad_category, true
    change_column_default :ad_campaigns, :special_ad_category, from: "NONE", to: nil
  end
end
