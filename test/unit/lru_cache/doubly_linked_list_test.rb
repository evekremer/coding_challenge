require_relative "../../test_helper"

# Test DoublyLinkedList class
class DoublyLinkedListTest < BaseTest
  def setup
    @empty_list = DoublyLinkedList.new

    @linked_list = DoublyLinkedList.new
    @data = Array.new
    10.times{ |i|
      @data[i] = {key: "#{key}#{i}", value: "#{value}#{i}"}
      @linked_list.insert_new_head @data[i]
    }
    @data.reverse!
  end

  # Loops over the list and compares items with 'data' one by one
  def validate_each list, data
    current = list.head
    i = 0
    expected_data = true
    while current
      expected_data &= current.data == data[i]
      current = current.next
      i += 1
    end
    expected_data
  end

  def validate_prev_next_head node
    !node.prev && node.next
  end

  ## Test insert_new_head

  def test_insert_new_data_first_element
    @empty_list.insert_new_head @data[0]
    
    assert_equal @empty_list.head, @empty_list.tail
    assert_nil @empty_list.head.next
    assert_nil @empty_list.head.prev
  end

  def test_insert_new_data_list
    new_data = {key: key, value: value}
    new_head_node = @linked_list.insert_new_head new_data

    assert validate_prev_next_head new_head_node

    assert_equal @linked_list.head.data, new_data
    assert validate_each @linked_list, ([new_data] + @data)
  end

  ## Test insert_head

  def test_insert_tail_into_head
    # Insert the tail of the list at the head
    tail_node = @linked_list.tail
    new_head_node = @linked_list.insert_head tail_node

    assert validate_prev_next_head new_head_node
    
    assert validate_each @linked_list, [@data[-1]] + @data[0..-2]
  end

  def test_insert_second_into_head
    # Insert second node of the list at the head
    node = @linked_list.head.next
    new_head_node = @linked_list.insert_head node

    assert validate_prev_next_head new_head_node
    assert validate_each @linked_list, ([@data[1]] + [@data[0]] + @data[2..-1])
  end

  def test_insert_head_into_head
    # Insert the head of the list at the head
    node = @linked_list.head
    new_head_node = @linked_list.insert_head node

    assert validate_prev_next_head new_head_node
    assert validate_each @linked_list, @data
  end

  def test_insert_nil
    assert_nil @linked_list.insert_head nil
  end

  ## Test remove

  def test_remove_length_one
    node = @empty_list.insert_new_head @data[0]

    # Removes the only element of the list (head)
    @empty_list.remove node

    assert_nil @empty_list.head
    assert_nil @empty_list.tail
  end

  def test_remove_list
    node = @linked_list.head.next
    # Remove the second element of the list (not head)
    removed_node = @linked_list.remove node

    assert validate_each @linked_list, [@data[0]] + @data[2..-1]
  end

  def test_remove_nil
    assert_nil @linked_list.remove nil
  end

end