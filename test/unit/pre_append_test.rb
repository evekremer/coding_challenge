# "prepend": means "add this data to an existing key before existing data".
# "append": means "add this data to an existing key after existing data".

require_relative "../test_helper"

class PreAppendTest < BaseTest
    
    ###########     Append     ###########

    def test_simple_append
        v1 = "start"
        send_storage_cmd("set", key, 2, 3000, v1.length(), false, v1, false)
        assert_equal STORED_MSG, socket.gets

        v2 = "end"
        send_storage_cmd("append", key, 2, 3000, v2.length(), false, v2, false)
        assert_equal STORED_MSG, socket.gets
        
        # Get the item and assert reply
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 2, (v1+v2).length(), v1+v2), reply
    end

    def test_missing_key_append
        value = "end"
        send_storage_cmd("append", key, 2, 3000, value.length(), false, value, false)
        assert_equal NOT_STORED_MSG, socket.gets

        # Get the item and assert reply
        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_empty_value_append
        send_storage_cmd("set", key, 2, 3000, value.length(), false, value, false)
        assert_equal STORED_MSG, socket.gets

        send_storage_cmd("append", key, 2, 400, 0, false, nil, false)
        assert_equal STORED_MSG, socket.gets
        
        # Get the item and assert reply
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 2, value.length(), value), reply
    end

    def test_no_reply_append
        send_storage_cmd("set", key, 3, 300, value.length(), false, value, false)
        assert_equal STORED_MSG, socket.gets
    
        value2 = "tail"
        send_storage_cmd("append", key, 4, 400, value2.length(), false, value2, true)
        # command with noreply
    
        # Get the item and assert reply
        # Note flags are ignored in append/prepend cmds
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 3, (value + value2).length(), value + value2), reply
    end

    ###########     Prepend     ###########

    def test_simple_prepend
        v2 = "end"
        send_storage_cmd("set", key, 2, 3000, v2.length(), false, v2, false)
        assert_equal STORED_MSG, socket.gets

        v1 = "start"
        send_storage_cmd("prepend", key, 2, 3000, v1.length(), false, v1, false)
        assert_equal STORED_MSG, socket.gets
        
        # Get the item and assert reply
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 2, (v1 + v2).length(), v1 + v2), reply
    end

    def test_missing_key_prepend
        v1 = "start"
        send_storage_cmd("prepend", key, 2, 3000, v1.length(), false, v1, false)
        assert_equal NOT_STORED_MSG, socket.gets

        # Get the item and assert reply
        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_empty_value_prepend
        send_storage_cmd("set", key, 2, 3000, value.length(), false, value, false)
        assert_equal STORED_MSG, socket.gets

        send_storage_cmd("prepend", key, 2, 400, 0, false, nil, false)
        assert_equal STORED_MSG, socket.gets
        
        # Get the item and assert reply
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 2, value.length(), value), reply
    end

    def test_no_reply_prepend
        send_storage_cmd("set", key, 3, 300, value.length(), false, value, false)
        assert_equal STORED_MSG, socket.gets
    
        value2 = "new_value"
        send_storage_cmd("prepend", key, 4, 400, value2.length(), false, value2, true)
        #command with noreply
    
        # Get the item and assert reply
        # Note flags are ignored in append/prepend cmds
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 3, (value2 + value).length(), value2 + value), reply
    end

    # ###########     Test invalid parameters     ###########
################################# FIX ! ###################################################################
    # def test_wrong_length_parameter
    #     send_storage_cmd("set", key, 2, 3000, value.length(), false, value, false)
    #     assert_equal STORED_MSG, socket.gets

    #     # Try appending / prepending with invalid length parameter
    #     send_storage_cmd("prepend", key, 2, 3000, "start".length()+5, false, "start", false)
    #     assert_equal "CLIENT_ERROR ...", socket.gets
        
    #     send_storage_cmd("append", key, 2, 3000, "end".length()+5, false, "end", false)
    #     assert_equal "CLIENT_ERROR ...", socket.gets

    #     # Get the item and assert reply with original value without changes
    #     # send_get_cmd([key])
    #     # reply = ""
    #     # 3.times { reply += "#{socket.gets}" }
    #     # assert_equal expected_get_response(key, 2, value.length(), value), reply
    # end
##########################################################################################
    def test_value_too_big
        send_storage_cmd("set", key, 2, 3000, value.length(), false, value, false)
        assert_equal STORED_MSG, socket.gets

        # Prepend / append a value that, combined with the existing value, exceeds max length
        v2 = "b" * (MAX_VALUE_LENGTH - value.length() + 1) # more than 1MB long
        send_storage_cmd("prepend", key, 2, 3000, v2.length(), false, v2, false)
        assert_equal "CLIENT_ERROR <value> has more than #{MAX_VALUE_LENGTH} characters\r\n", socket.gets

        send_storage_cmd("append", key, 2, 3000, v2.length(), false, v2, false)
        assert_equal "CLIENT_ERROR <value> has more than #{MAX_VALUE_LENGTH} characters\r\n", socket.gets
        
        # Get the item and assert reply without changes
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 2, value.length(), value), reply
    end  
end

