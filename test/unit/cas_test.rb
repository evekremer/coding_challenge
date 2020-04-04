#"cas" is a check and set operation which means "store this data but only if no one else has updated since I last fetched it."
require_relative "../test_helper"

class CasTest < BaseTest

    def test_simple_cas
        send_storage_cmd("set", key, 3, 300, value.length(), false, value, false)
        assert_equal STORED_MSG, socket.gets

        val2 = "new_value"
        send_storage_cmd("cas", key, 4, 400, val2.length(), 1, val2, false)
        assert_equal STORED_MSG, socket.gets

        # Get the item
        send_get_cmd([key])
        reply = ""
        3.times { reply += "#{socket.gets}" }
        assert_equal expected_get_response(key, 4, val2.length(), val2, true).concat(END_MSG), reply
    end

    def test_exists_cas
        send_storage_cmd("set", key, 2, 2000, value.length(), false, value, false)
        assert_equal STORED_MSG, socket.gets

        val2 = "new_value"
        send_storage_cmd("cas", key, 4, 400, val2.length(), 5, val2, false)
        assert_equal EXISTS_MSG, socket.gets

        # Get the original item without updates
        send_get_cmd([key])
        reply = ""
        3.times { reply += "#{socket.gets}" }
        assert_equal expected_get_response(key, 4, value.length(), value, true).concat(END_MSG), reply
    end

    def test_not_found_cas
        send_storage_cmd("cas", key, 4, 400, value.length(), 5, value, false)
        assert_equal NOT_FOUND_MSG, socket.gets

        send_get_cmd([key])
        assert_equal END_MSG, socket.gets
    end

    def test_no_reply_cas
        send_storage_cmd("set", key, 3, 300, value.length(), false, value, false)
        assert_equal STORED_MSG, socket.gets

        val2 = "new_value"
        send_storage_cmd("cas", key, 4, 400, val2.length(), 1, val2, true)

        # Get the item
        send_get_cmd([key])
        reply = ""
        3.times { reply += "#{socket.gets}" }
        assert_equal expected_get_response(key, 4, val2.length(), val2, true).concat(END_MSG), reply
    end

    ####     Test invalid parameters

    def test_negative_cas_unique_key
        send_storage_cmd("cas", key, 3, 300, value.length(), -2, value, false)
        assert_equal "CLIENT_ERROR ...", socket.gets

        send_get_cmd([key])
        assert_equal END_MSG, socket.gets
    end

    # cas_unique_key bigger than the maximum 64-bit integer
    def test_exceeds_max_cas_unique_key
        send_storage_cmd("cas", key, 3, 300, value.length(), (2**64)+1, value, false)
        assert_equal "CLIENT_ERROR ...", socket.gets

        send_get_cmd([key])
        assert_equal END_MSG, socket.gets
    end

    def test_string_cas_unique_key
        send_storage_cmd("cas", key, 3, 300, value.length(), "unique_cas_key", value, false)
        assert_equal "CLIENT_ERROR ...", socket.gets

        send_get_cmd([key])
        assert_equal END_MSG, socket.gets
    end

    def test_nil_cas_unique_key
        send_storage_cmd("cas", key, 3, 300, value.length(), nil, value, false)
        assert_equal "CLIENT_ERROR ...", socket.gets

        send_get_cmd([key])
        assert_equal END_MSG, socket.gets
    end
end