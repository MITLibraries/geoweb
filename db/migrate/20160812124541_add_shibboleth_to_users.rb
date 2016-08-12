class AddShibbolethToUsers < ActiveRecord::Migration[5.0]
  def change
    change_table :users do |t|
      t.string :name
      t.string :uid
      t.index :uid, unique: true
    end
  end
end
