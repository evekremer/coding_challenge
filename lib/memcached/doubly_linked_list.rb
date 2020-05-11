class DoublyLinkedList
  class Node
		attr_accessor :prev, :next, :data
    
    def initialize data
			self.data = data
			self.prev = nil
		end
	end

  attr_accessor :head, :tail, :length
  
	def initialize
		self.head   = nil
		self.tail   = nil
		self.length = 0
  end

	# Inserts a new item into the head of the list
	# Complexity: O(1)
  def insert_head data
    node = Node.new data
    success = update_head node
    return nil unless success
    
    self.length += 1 
    node
  end

  # Updates the head of the list
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

	# Removes an item from the list
	# Complexity: O(1)
  def remove node
		return nil unless node

		if node == head
			if head.next.nil?
				self.head = self.tail = nil
			else
				self.head = self.head.next
			end
		else
			p = node.prev
			n = node.next
			p&.next = n
			n&.prev = p
		end
    self.length -= 1
    node
	end
end