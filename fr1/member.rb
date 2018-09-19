bin/rake db:create
bin/rake db:create RAILS_ENV=production
bin/rake db:drop
vi config/application.rb
module App
  class Application < Rails::Application
    config.time_zone = 'Tokyo'
  end
end
bin/rake -T
bin/rails g model member
vi db/migrate/20180920054900_create_members.rb
class CreateMembers < ActiveRecord::Migration
  def change
    create_table :members do |t|
	  t.integer :number, null:false
	  t.string :name, null:false
	  t.string :full_name
	  t.string :email
	  t.date :birthday
	  t.integer :gender, null: false, default: 0
	  t.boolean :administrator, null: false, default: false
	  t.timestamps
	end
  end
end
bin/rake db:migrate/20180920054900_create_members
bin/rake db:migrate RAILS_ENV=production
bin/rails g migration ModifyMembers
vi migrate/modify_members.rb
class ModifyMembers < ActiveRecord::Migration
  def change
    add_column :members, :phone, :string
  end
end



