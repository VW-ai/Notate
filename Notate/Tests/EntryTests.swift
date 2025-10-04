import Foundation

// Simple test file to verify core functionality
// This would normally be in a proper test target

class EntryTests {
    static func runTests() {
        testEntryCreation()
        testTypeDetection()
        testContentCleaning()
        testConversion()
        print("✅ All tests passed!")
    }
    
    static func testEntryCreation() {
        let entry = Entry(
            type: EntryType.todo,
            content: "Test content",
            triggerUsed: "///"
        )
        
        assert(entry.type == EntryType.todo)
        assert(entry.content == "Test content")
        assert(entry.triggerUsed == "///")
        assert(entry.status == EntryStatus.open)
        assert(entry.priority == nil)
        
        print("✅ Entry creation test passed")
    }
    
    static func testTypeDetection() {
        let configManager = ConfigurationManager.shared
        
        // Test trigger mapping
        let type1 = configManager.detectEntryType(from: "buy milk", triggerUsed: "///")
        assert(type1 == EntryType.todo)
        
        let type2 = configManager.detectEntryType(from: "random idea", triggerUsed: ",,,")
        assert(type2 == EntryType.thought)
        
        // Test inline overrides
        let type3 = configManager.detectEntryType(from: "todo: test", triggerUsed: ",,,")
        assert(type3 == EntryType.todo)
        
        let type4 = configManager.detectEntryType(from: "idea: test", triggerUsed: "///")
        assert(type4 == EntryType.thought)
        
        // Test Chinese overrides
        let type5 = configManager.detectEntryType(from: "待办: 测试", triggerUsed: ",,,")
        assert(type5 == EntryType.todo)
        
        let type6 = configManager.detectEntryType(from: "想法: 测试", triggerUsed: "///")
        assert(type6 == EntryType.thought)
        
        print("✅ Type detection test passed")
    }
    
    static func testContentCleaning() {
        let configManager = ConfigurationManager.shared
        
        let cleaned1 = configManager.cleanContent("todo: buy milk")
        assert(cleaned1 == "buy milk")
        
        let cleaned2 = configManager.cleanContent("idea: random thought")
        assert(cleaned2 == "random thought")
        
        let cleaned3 = configManager.cleanContent("待办: 做作业")
        assert(cleaned3 == "做作业")
        
        let cleaned4 = configManager.cleanContent("想法: 新想法")
        assert(cleaned4 == "新想法")
        
        print("✅ Content cleaning test passed")
    }
    
    static func testConversion() {
        var thought = Entry(
            type: EntryType.thought,
            content: "Test thought",
            tags: ["test", "idea"],
            triggerUsed: ",,,"
        )
        
        let convertedTodo = thought.convertToTodo()
        
        assert(convertedTodo.type == EntryType.todo)
        assert(convertedTodo.content == "Test thought")
        assert(convertedTodo.status == EntryStatus.open)
        assert(convertedTodo.priority == EntryPriority.medium)
        assert(convertedTodo.tags == ["test", "idea"])
        assert(convertedTodo.metadata?["converted_from"]?.wrappedValue as? String == "thought")
        
        var todo = Entry(
            type: EntryType.todo,
            content: "Test task",
            tags: ["urgent", "work"],
            triggerUsed: "///",
            status: EntryStatus.done,
            priority: EntryPriority.high
        )
        
        let convertedThought = todo.convertToThought()
        
        assert(convertedThought.type == EntryType.thought)
        assert(convertedThought.content == "Test task")
        assert(convertedThought.status == EntryStatus.open)
        assert(convertedThought.priority == nil)
        assert(convertedThought.tags == ["urgent", "work"])
        assert(convertedThought.metadata?["converted_from"]?.wrappedValue as? String == "todo")
        
        print("✅ Conversion test passed")
    }
}

// Extension to make testing easier
extension FlexibleCodable {
    var value: Any {
        return self.wrappedValue
    }
}
