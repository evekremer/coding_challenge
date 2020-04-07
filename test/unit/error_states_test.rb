require_relative "../test_helper"

class ErrorStatesTest < BaseTest
    
    ####### Invalid command termination and types
    
    def test_bad_termination_get
        socket.puts "get #{key}"
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_bad_termination_set
        socket.puts "set #{key} 5 5000 6"
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_bad_termination_datablock
        socket.puts "set key 9 89 5\r\n"
        socket.puts "value"
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_empty_string_cmd
        socket.puts ""
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_numeric_command
        socket.puts 111111
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_nil_command
        socket.puts nil
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_empty_command_1
        socket.puts "\r\n"
        socket.puts "value\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
    end

    def test_empty_command_2
        socket.puts ""
        socket.puts "value\r\n"
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end
    
    def test_duplicate_command
        socket.puts "set key 9 89 5\r\nset key 9 89 5\r\n"
        socket.puts "value\r\n"
        reply = socket.gets
        #Takes 'set key 9 89 5\r\nvalue\r\n' as the value
        assert_equal "CLIENT_ERROR <length> (#{"value".length()}) is not equal to the length of the item's value (#{"set key 9 89 5\r\nvalue".length()})\r\n", reply
    end

    ###### Key and value that exceed max length

    def test_key_too_long
        key = "k" * (MAX_KEY_LENGTH + 1)

        send_storage_cmd("set", key, 4, 6230, value.length(), false, value, false)
        assert_equal "CLIENT_ERROR <key> has more than #{MAX_KEY_LENGTH} characters\r\n", socket.gets

        socket.puts "get #{key}\r\n"
        assert_equal "CLIENT_ERROR <key> has more than #{MAX_KEY_LENGTH} characters\r\n", socket.gets
    end

    def test_value_too_long
        value = "v" * (MAX_VALUE_LENGTH + 1)

        send_storage_cmd("set", key, 4, 6230, value.length(), false, value, false)
        assert_equal "CLIENT_ERROR <value> has more than #{MAX_VALUE_LENGTH} characters\r\n", socket.gets
        
        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_noreply_syntax_error_set
        socket.puts "set #{key} 5 300 5 norep\r\n"
        socket.puts "value\r\n"
        assert_equal "CLIENT_ERROR A 'noreply' was expected as the 6th argument, but 'norep' was received\r\n", socket.gets
    end

    def test_noreply_syntax_error_cas
        socket.puts "cas #{key} 5 300 5 10 noreplynoreply\r\n"
        socket.puts "value\r\n"
        assert_equal "CLIENT_ERROR A 'noreply' was expected as the 7th argument, but 'noreplynoreply' was received\r\n", socket.gets
    end


    ####### Invalid command name

    def test_invalid_command_name_1
        socket.puts "invalid_command_name #{key} 4 400 9\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_invalid_command_name_2
        socket.puts "se #{key} 4 400 9\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
    
        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_invalid_command_name_3
        socket.puts "sett #{key} 4 400 9\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_invalid_command_name_3
        socket.puts "  #{key} 4 400 9\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_invalid_command_name_4
        socket.puts "\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    # Case sensitive command name

    def test_case_sensitive_set
        socket.puts "SET #{key} 5 5000 2\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end
    
    def test_case_sensitive_add
        socket.puts "ADD #{key} 5 5000 2\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end
    
    def test_case_sensitive_replace
        socket.puts "REPLACE #{key} 5 5000 2\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_case_sensitive_prepend
        socket.puts "PREPEND #{key} 5 5000 2\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_case_sensitive_append
        socket.puts "APPEND #{key} 5 5000 2\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end
    
    def test_case_sensitive_cas
        socket.puts "CAS #{key} 5 5000 2 1\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_case_sensitive_get
        socket.puts "GET #{key}\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
    end

    def test_case_sensitive_gets
        socket.puts "GETS #{key}\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
    end
end