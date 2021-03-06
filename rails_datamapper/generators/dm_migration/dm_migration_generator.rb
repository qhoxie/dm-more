require 'rails_generator/generators/components/migration/migration_generator'
require 'active_record'

class DmMigrationGenerator < Rails::Generator::NamedBase

  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate'
    end
  end
end
