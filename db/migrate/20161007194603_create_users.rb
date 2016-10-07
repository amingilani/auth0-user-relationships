class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :auth0_uid

      t.timestamps
    end
    add_index :users, :auth0_uid
  end
end
