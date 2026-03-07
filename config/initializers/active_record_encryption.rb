# Configure Active Record Encryption keys from environment variables
# During asset precompilation (SECRET_KEY_BASE_DUMMY), use dummy values
# since encryption keys aren't needed for compiling assets.
Rails.application.config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY") { "dummy" if ENV["SECRET_KEY_BASE_DUMMY"] }
Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY") { "dummy" if ENV["SECRET_KEY_BASE_DUMMY"] }
Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT") { "dummy" if ENV["SECRET_KEY_BASE_DUMMY"] }
