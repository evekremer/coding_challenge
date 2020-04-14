require_relative "../test_helper"

class PurgeExpiredTest < BaseTest

    def test_exptime_set
        # Set item that expires in 3 seconds (exptime = 3)
        send_storage_cmd("set", key, 8, 3, value.length(), false, value, false)
        assert_equal Memcached::STORED_MSG, read_reply

        # Get stored item
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 8, value.length(), value), reply

        wait_for_purge_exec

        # Get expired item
        reply = send_get_cmd(key)
        assert_equal Memcached::END_MSG, reply
    end

    def test_set_negative_and_unix_exptime
        # Set item that expires immediately (exptime < 0)
        exptime = -3
        send_storage_cmd("set", "#{key}1", 1, exptime, value.length(), false, value, false)
        assert_equal Memcached::STORED_MSG, read_reply

        # Set item with unix exptime (exptime >= 30 days)
        # 1 second from 1/1/1970
        exptime = (30 * Memcached::SECONDS_PER_DAY) + 1
        send_storage_cmd("set", "#{key}2", 4, exptime, value.length(), false, value, false)
        assert_equal Memcached::STORED_MSG, read_reply

        # 50 seconds prior current time
        exptime = (30 * Memcached::SECONDS_PER_DAY) + Time.now.to_i - 50
        send_storage_cmd("set", "#{key}3", 8, exptime, value.length(), false, value, false)
        assert_equal Memcached::STORED_MSG, read_reply
        
        wait_for_purge_exec

        # Multiple get for expired items
        reply = send_get_cmd(["#{key}1", "#{key}2", "#{key}3"])
        assert_equal Memcached::END_MSG, reply
    end

    def test_set_unix_exptime_not_expired
        # Set item with unix exptime (exptime >= 30 days)
        # 120 seconds from current time in unix
        exptime = (30 * Memcached::SECONDS_PER_DAY) + Time.now.to_i + 120
        
        send_storage_cmd("set", key, 9, exptime, value.length(), false, value, false)
        assert_equal Memcached::STORED_MSG, read_reply
        
        wait_for_purge_exec

        # Get not expired item
        reply = send_get_cmd(key)
        assert_equal expected_get_response(key, 9, value.length(), value), reply
    end

    def test_set_multi_all_expired
        keys = Array.new
        exptime = 0

        8.times{ |i|
            key_ = "key_exp#{i}"
            value_ = "value_exp#{i}"
            
            send_storage_cmd("set", key_, 4, exptime+1, value_.length(), false, value_, true)
            keys[i] = key_
        }

        wait_for_purge_exec

        # Get multiple expired keys
        send_get_multi_keys(keys)
        assert_equal Memcached::END_MSG, read_reply
    end

    def test_set_multi_some_expired
        exp_reply_multi = ""
        keys = Array.new

        20.times{ |i|
            key_ = "#{key}#{i}"
            value_ = "#{value}#{i}"
            if i < 10
                # Immediatelly expires (exptime = -1)
                send_storage_cmd("set", key_, 4, -1, value_.length(), false, value_, true)
            else
                # Expires in 1000 seconds
                send_storage_cmd("set", key_, 4, 1000, value_.length(), false, value_, true)
                exp_reply_multi += expected_get_response(key_, 4, value_.length(), value_, false, true)
            end
            keys[i] = key_
        }

        wait_for_purge_exec

        # Get multiple expired keys
        exp_reply_multi.concat(Memcached::END_MSG)

        send_get_multi_keys(keys)
        reply_multi = read_reply((10 * 2) + 1)
        
        assert_equal exp_reply_multi, reply_multi
    end
end