# Notate Demo Guide

## Quick Start Demo

### 1. Launch the App
- Open Notate in Xcode and run it
- Grant accessibility permissions when prompted
- The app will start monitoring for triggers globally

### 2. Test Basic Capture
Open any text editor or chat app and try these examples:

#### TODO Capture
```
/// buy milk
/// 做作业
/// t: book dentist appointment
```

#### Thought Capture
```
,,, idea: link shopping list with geofence reminders
,,, 想法：把购物清单和地理位置联动
,,, i: 观察：周一早上最容易分心
```

#### Custom Triggers
```
;; test custom trigger
!!! urgent task
>>> another idea
```

### 3. View Captured Entries
- Switch between tabs: All, TODOs, Thoughts
- Use search to find specific entries
- Apply filters by status or priority
- Expand entries to see full details

### 4. Manage Entries
- **Mark TODOs as done**: Click checkbox or swipe right
- **Convert Thoughts to TODOs**: Swipe right on thought entries
- **Delete entries**: Swipe left and tap delete
- **Edit priorities**: Expand TODO entries

### 5. Configure Settings
- Add new triggers in Settings
- Set default types for triggers
- Adjust capture timeout
- Enable/disable auto-clear input
- Toggle IME composing support

## Example Workflows

### Daily Task Management
1. **Morning planning**: `/// review emails`, `/// prepare presentation`
2. **Throughout day**: `/// call client`, `/// update project status`
3. **Evening review**: Check TODOs tab, mark completed items

### Idea Capture
1. **Random thoughts**: `,,, idea: gamify productivity app`
2. **Observations**: `,,, 想法：用户更喜欢简单的界面`
3. **Convert to action**: Swipe to convert promising ideas to TODOs

### Multilingual Usage
1. **Mixed content**: `/// 买牛奶 and check email`
2. **Chinese tasks**: `/// 完成报告`, `/// 联系客户`
3. **English thoughts**: `,,, idea: implement dark mode`

## Advanced Features

### Inline Type Overrides
Force entry type regardless of trigger:
- `todo:` or `t:` → Always creates TODO
- `idea:` or `i:` → Always creates Thought
- `待办:` or `任务:` → Always creates TODO (Chinese)
- `想法:` or `思考:` → Always creates Thought (Chinese)

### Priority Management
TODOs automatically get medium priority, can be adjusted:
- High priority: Red badge
- Medium priority: Orange badge  
- Low priority: Green badge

### Tag System
- Automatic tag extraction (future feature)
- Manual tag management
- Search by tags
- Filter by tags

### Export & Backup
- Export all data as JSON
- Export as CSV for spreadsheet apps
- Clear all data option
- Database location: `~/Library/Application Support/Notate/`

## Troubleshooting Demo

### If Capture Doesn't Work
1. Check System Settings > Privacy & Security > Accessibility
2. Ensure Notate is enabled and has permission
3. Try restarting the app
4. Check Console.app for error messages

### If Chinese Input Issues
1. Enable "IME composing support" in Settings
2. Try typing slower to allow IME processing
3. Use simpler triggers for Chinese input

### If Database Issues
1. Check Application Support folder permissions
2. Try exporting data and clearing database
3. Restart the app to reinitialize database

## Performance Tips

### Optimal Trigger Length
- **Short triggers**: `;;`, `,,` (fast typing)
- **Medium triggers**: `///`, `,,,` (good balance)
- **Long triggers**: `!!!!`, `>>>>` (less accidental triggers)

### Capture Timeout
- **Fast typers**: 1-2 seconds
- **Normal typers**: 3-4 seconds  
- **Slow typers**: 5-10 seconds

### Memory Management
- App automatically manages memory
- Large databases (>10k entries) may need optimization
- Export old entries periodically

## Integration Examples

### With Other Apps
- **Slack**: `/// follow up with team` (auto-clears input)
- **WhatsApp**: `,,, idea: weekend project` (prevents accidental send)
- **Notes**: `/// research topic` (captures without interrupting flow)
- **Email**: `/// reply to client` (saves draft, clears compose)

### Workflow Integration
- **GTD Method**: Capture → Process → Organize → Review
- **Pomodoro**: `/// 25min focus session`
- **Daily Standup**: `/// demo feature X`
- **Meeting Notes**: `,,, idea: improve onboarding`

This demo shows the core functionality and real-world usage patterns of the Notate app.
