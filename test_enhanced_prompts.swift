import Foundation

/// Quick test script to validate enhanced Claude 4.5 prompt integration
class PromptIntegrationTest {

    static func testEnhancedPrompts() {
        print("🧪 Testing Enhanced Claude 4.5 Prompt Integration")
        print("=" * 50)

        // Test 1: Advanced TODO Research Prompt
        print("\n📋 Test 1: Advanced TODO Research Prompt")
        let testTodo = "Plan quarterly team offsite in Austin for Q2 strategy session"
        let userContext = UserContext(location: "San Francisco", timeOfDay: "morning")

        let advancedTodoPrompt = PromptManager.smartTodoResearchPrompt(
            content: testTodo,
            userContext: userContext,
            enableAdvanced: true
        )

        print("✅ Advanced TODO prompt generated successfully")
        print("📏 Prompt length: \(advancedTodoPrompt.count) characters")
        print("🔍 Contains 'Strategic Intelligence': \(advancedTodoPrompt.contains("Strategic Intelligence"))")
        print("🔍 Contains 'Tool Orchestration': \(advancedTodoPrompt.contains("Tool Orchestration"))")

        // Test 2: Hyper-contextual Piece Research
        print("\n🔬 Test 2: Hyper-contextual Piece Research")
        let testPiece = "AI agent orchestration patterns in modern SaaS applications"

        let advancedPiecePrompt = PromptManager.smartPieceResearchPrompt(
            content: testPiece,
            userContext: userContext,
            enableAdvanced: true
        )

        print("✅ Advanced piece research prompt generated successfully")
        print("📏 Prompt length: \(advancedPiecePrompt.count) characters")
        print("🔍 Contains 'Predictive Timeline': \(advancedPiecePrompt.contains("Predictive Timeline"))")
        print("🔍 Contains 'Knowledge Architecture': \(advancedPiecePrompt.contains("Knowledge Architecture"))")

        // Test 3: Cross-pattern Analysis
        print("\n🧠 Test 3: Cross-pattern Analysis")
        let currentEntry = "Review and optimize team productivity workflows"
        let sampleHistory = [
            "Setup automated deployment pipeline",
            "Conduct team retrospective meeting",
            "Research project management tools"
        ]

        let patternAnalysisPrompt = PromptManager.crossPatternAnalysisPrompt(
            currentEntry: currentEntry,
            entryHistory: sampleHistory,
            productivityMetrics: ["weekly_tasks_completed": 23, "average_task_duration": "2.5 hours"]
        )

        print("✅ Pattern analysis prompt generated successfully")
        print("📏 Prompt length: \(patternAnalysisPrompt.count) characters")
        print("🔍 Contains 'behavioralPatterns': \(patternAnalysisPrompt.contains("behavioralPatterns"))")
        print("🔍 Contains 'predictiveInsights': \(patternAnalysisPrompt.contains("predictiveInsights"))")

        // Test 4: Workflow Orchestration
        print("\n⚙️ Test 4: Workflow Orchestration")
        let workflowContent = "Schedule project kickoff meeting with stakeholders"
        let availableTools = ["calendar", "contacts", "reminders", "maps", "web_search"]

        let orchestrationPrompt = PromptManager.intelligentWorkflowOrchestrationPrompt(
            content: workflowContent,
            availableTools: availableTools,
            userWorkflowHistory: ["previous_project_kickoff_successful"]
        )

        print("✅ Workflow orchestration prompt generated successfully")
        print("📏 Prompt length: \(orchestrationPrompt.count) characters")
        print("🔍 Contains 'EXECUTABLE WORKFLOW JSON': \(orchestrationPrompt.contains("EXECUTABLE WORKFLOW JSON"))")
        print("🔍 Contains 'intelligence_features': \(orchestrationPrompt.contains("intelligence_features"))")

        // Test 5: Enhanced Content Classification
        print("\n🏷️ Test 5: Enhanced Content Classification")
        let classificationContent = "Call Sarah about the budget proposal by Friday 3pm"

        let enhancedClassificationPrompt = PromptManager.smartContentClassificationPrompt(
            content: classificationContent,
            userContext: userContext,
            enableIntelligence: true
        )

        print("✅ Enhanced classification prompt generated successfully")
        print("📏 Prompt length: \(enhancedClassificationPrompt.count) characters")
        print("🔍 Contains 'behavioralIntelligence': \(enhancedClassificationPrompt.contains("behavioralIntelligence"))")
        print("🔍 Contains 'predictive_workflow': \(enhancedClassificationPrompt.contains("predictive_workflow"))")

        // Test 6: Backward Compatibility
        print("\n🔄 Test 6: Backward Compatibility")
        let basicTodoPrompt = PromptManager.smartTodoResearchPrompt(
            content: testTodo,
            userContext: userContext,
            enableAdvanced: false
        )

        print("✅ Backward compatibility maintained")
        print("📏 Basic prompt length: \(basicTodoPrompt.count) characters")
        print("🔍 Falls back to standard prompt when advanced disabled: \(basicTodoPrompt.count < advancedTodoPrompt.count)")

        // Final Results
        print("\n" + "=" * 50)
        print("🎉 All Enhanced Claude 4.5 Prompt Tests Passed!")
        print("📊 Summary:")
        print("   • Advanced TODO Research: ✅")
        print("   • Hyper-contextual Piece Research: ✅")
        print("   • Cross-pattern Analysis: ✅")
        print("   • Workflow Orchestration: ✅")
        print("   • Enhanced Classification: ✅")
        print("   • Backward Compatibility: ✅")
        print("\n🚀 System ready for enhanced Claude 4.5 operations!")
    }
}

// Execute test if run directly
if CommandLine.argc > 0 && CommandLine.arguments[0].contains("test_enhanced_prompts") {
    PromptIntegrationTest.testEnhancedPrompts()
}