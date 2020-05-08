require_relative "../../test_helper"

# Test retrieval_handler method for CacheHandler class
class RetrievalHandlerTest < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
  end
end