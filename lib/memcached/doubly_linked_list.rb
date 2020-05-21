# frozen_string_literal: true

# Doubly linked lists allows to traverse the list
# from tail to head and remove elements in constant time
class DoublyLinkedList
  # Each node contain three attributes:
  # the value the element holds, and pointers to the next and previous nodes
  class Node
    attr_accessor :prev, :next, :data

    def initialize(data)
      self.data = data
      self.prev = nil
      self.next = nil
    end
  end

  attr_accessor :head, :tail

  def initialize
    self.head   = nil
    self.tail   = nil
  end

  # Inserts a new data into the head of the list
  # Complexity: O(1)
  def insert_new_head(data)
    node = Node.new data
    update_head node
    node
  end

  # Inserts a node into the head of the list
  # Complexity: O(1)
  def insert_head(node)
    removed_node = remove node
    return nil unless removed_node

    update_head removed_node
  end

  # Removes an item from the list
  # Complexity: O(1)
  def remove(node)
    return nil unless node

    if node == head
      remove_head
    elsif node == tail
      remove_tail
    else
      update_node_pointers node
    end

    node.prev = node.next = nil
    node
  end

  private

  def remove_tail
    self.tail = tail.prev
    tail.next = nil
  end

  def remove_head
    if head.next.nil?
      self.head = self.tail = nil
    else
      self.head = head.next
      head.prev = nil
    end
  end

  def update_node_pointers(node)
    p = node.prev
    n = node.next
    p&.next = n
    n&.prev = p
  end

  # Sets the head of the list
  # Complexity: O(1)
  def update_head(node)
    return nil unless node

    if tail
      node.next = head
      head.prev = node
    else
      self.tail = node
    end
    self.head = node
  end
end
