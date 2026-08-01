ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

module ActiveSupport
  class TestCase
    # Not parallelized: the test suite shares the dev Supabase project's
    # small connection pool (see config/database.yml), and this suite is
    # small enough that parallel workers wouldn't meaningfully speed it up.
    parallelize(workers: 1)

    # No YAML fixtures — test data is built inline per test via
    # SeasonTestHelper. Fixture loading also doesn't work against Supabase:
    # it tries to validate foreign keys database-wide, including Supabase's
    # own `auth` schema, which our restricted connection role can't touch.

    include SeasonTestHelper
  end
end
