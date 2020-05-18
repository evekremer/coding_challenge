class DoublyLinkedList
  class Node
		attr_accessor :prev, :next, :data
    
    def initialize data
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
  def insert_new_head data
    node = Node.new data
    update_head node
    node
  end

  # Inserts a node into the head of the list
  # Complexity: O(1)
  def insert_head node
    removed_node = remove node
    return nil unless removed_node

    update_head removed_node
  end

	# Removes an item from the list
	# Complexity: O(1)
  def remove node
		return nil unless node

		if node == head
			if head.next.nil?
				self.head = self.tail = nil
			else
        self.head = self.head.next
        self.head.prev = nil
      end
    elsif node == tail
      self.tail = self.tail.prev
      self.tail.next = nil
		else
			p = node.prev
			n = node.next
			p&.next = n
			n&.prev = p
    end
    
    node.prev = node.next = nil
    node
  end
  
  private

  # Sets the head of the list
	# Complexity: O(1)
  def update_head node
    return nil unless node
    
		unless tail
			self.tail = node
		else
			node.next = self.head
			self.head.prev = node
		end
    self.head = node
	end
end