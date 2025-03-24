import 'package:flutter/material.dart';
import '../color_reference.dart';

class CalendarWidget extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final Function(DateTime)? onViewChanged;
  final Map<DateTime, List<String>>? events; // Key: Date, Value: List of event titles
  final Function(DateTime, String)? onEventAdded;
  final Function(DateTime, String)? onEventDeleted;

  const CalendarWidget({
    super.key,
    this.onDateSelected,
    this.onViewChanged,
    this.events,
    this.onEventAdded,
    this.onEventDeleted,
  });

  @override
  CalendarWidgetState createState() => CalendarWidgetState();
}

class CalendarWidgetState extends State<CalendarWidget> {
  int _currentViewIndex = 0; // 0: Year, 1: Month, 2: Week, 3: Day
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildCurrentView()), // Ensure Expanded is used here
        _buildNavigationBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
            onPressed: _goToPrevious,
          ),
          Text(
            _getTitle(),
            style: const TextStyle(color: AppColors.primaryColor, fontSize: 20),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.primaryColor),
            onPressed: _goToNext,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentViewIndex,
      onTap: (index) {
        setState(() {
          _currentViewIndex = index;
          if (widget.onViewChanged != null) {
            widget.onViewChanged!(_focusedDate);
          }
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Year',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Month',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_view_week),
          label: 'Week',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_view_day),
          label: 'Day',
        ),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_currentViewIndex) {
      case 0:
        return _buildYearView();
      case 1:
        return _buildMonthView();
      case 2:
        return _buildWeekView();
      case 3:
        return _buildDayView();
      default:
        return _buildMonthView();
    }
  }

  Widget _buildYearView() {
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.5,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthDate = DateTime(_focusedDate.year, index + 1, 1);
          return GestureDetector(
            onTap: () => _onDateSelected(monthDate),
            child: Card(
              child: Center(child: Text(_getMonthName(index))),
            ),
          );
        },
      );
    });
  }

  Widget _buildMonthView() {
    final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(firstDay.year, firstDay.month);

    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          final dayDate = DateTime(firstDay.year, firstDay.month, index + 1);
          return GestureDetector(
            onTap: () => _onDateSelected(dayDate),
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${dayDate.day}'),
                  if (widget.events?[dayDate]?.isNotEmpty ?? false)
                    const Icon(Icons.event, color: Colors.blue, size: 12),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildWeekView() {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final weekDate = _focusedDate.add(Duration(days: index));
        return ListTile(
          title: Text('${weekDate.day} ${_getMonthName(weekDate.month - 1)}'),
          onTap: () => _onDateSelected(weekDate),
        );
      },
    );
  }

  Widget _buildDayView() {
    final events = widget.events?[_focusedDate] ?? [];
    return Column(
      children: [
        Text(
          '${_focusedDate.day} ${_getMonthName(_focusedDate.month - 1)}, ${_focusedDate.year}',
          style: const TextStyle(fontSize: 18),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(events[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    if (widget.onEventDeleted != null) {
                      widget.onEventDeleted!(_focusedDate, events[index]);
                    }
                  },
                ),
              );
            },
          ),
        ),
        TextButton(
          onPressed: _addEvent,
          child: const Text('Add Event'),
        ),
      ],
    );
  }

  void _goToPrevious() {
    setState(() {
      switch (_currentViewIndex) {
        case 0:
          _focusedDate = DateTime(_focusedDate.year - 1);
          break;
        case 1:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
          break;
        case 2:
          _focusedDate = _focusedDate.subtract(const Duration(days: 7));
          break;
        case 3:
          _focusedDate = _focusedDate.subtract(const Duration(days: 1));
          break;
      }
    });
  }

  void _goToNext() {
    setState(() {
      switch (_currentViewIndex) {
        case 0:
          _focusedDate = DateTime(_focusedDate.year + 1);
          break;
        case 1:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
          break;
        case 2:
          _focusedDate = _focusedDate.add(const Duration(days: 7));
          break;
        case 3:
          _focusedDate = _focusedDate.add(const Duration(days: 1));
          break;
      }
    });
  }

  void _onDateSelected(DateTime date) {
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date);
    }
  }

  void _addEvent() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController eventController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Event'),
          content: TextField(
            controller: eventController,
            decoration: const InputDecoration(hintText: 'Event Title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (widget.onEventAdded != null) {
                  widget.onEventAdded!(_focusedDate, eventController.text);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _getTitle() {
    switch (_currentViewIndex) {
      case 0:
        return '${_focusedDate.year}';
      case 1:
        return '${_getMonthName(_focusedDate.month - 1)} ${_focusedDate.year}';
      case 2:
        return 'Week of ${_focusedDate.day}';
      case 3:
        return '${_focusedDate.day} ${_getMonthName(_focusedDate.month - 1)}';
      default:
        return '';
    }
  }

  String _getMonthName(int index) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[index];
  }
}
