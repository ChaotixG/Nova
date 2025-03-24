import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../app_state.dart';
import '../widgets/calendar_widget.dart';

class CalendarState extends AppState {
  final Function(AppState) onStateChange;

  const CalendarState({super.key, required this.onStateChange});

  @override
  Widget build(BuildContext context) {
    return CalendarView(onStateChange: onStateChange);
  }
}

class CalendarView extends StatefulWidget {
  final Function(AppState) onStateChange;

  const CalendarView({super.key, required this.onStateChange});

  @override
  CalendarViewState createState() => CalendarViewState();
}

class CalendarViewState extends State<CalendarView> {
  final Map<DateTime, List<Event>> _events = {};
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  List<Event> _getEventsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _events[normalizedDate] ?? [];
  }

  void _addEvent() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        return AlertDialog(
          title: const Text("Add Event"),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: "Event title"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text;
                if (title.isNotEmpty) {
                  setState(() {
                    final normalizedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                    );
                    _events.putIfAbsent(normalizedDate, () => []);
                    _events[normalizedDate]?.add(Event(title: title));
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteEvent(Event event) {
    setState(() {
      final normalizedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      _events[normalizedDate]?.remove(event);
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsForSelectedDate = _getEventsForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addEvent,
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            child: CalendarWidget(
              onDateSelected: _onDateSelected,
              onViewChanged: (date) {
                // View change handler
              },
            ),
          ),
          if (eventsForSelectedDate.isNotEmpty)
            Flexible(
              child: ListView.builder(
                itemCount: eventsForSelectedDate.length,
                itemBuilder: (context, index) {
                  final event = eventsForSelectedDate[index];
                  return Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          icon: Icons.delete,
                          label: "Delete",
                          backgroundColor: Colors.red,
                          onPressed: (_) => _deleteEvent(event),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(event.title),
                    ),
                  );
                },
              ),
            )
          else
            const Flexible(
              child: Center(
                child: Text("No events for this date."),
              ),
            ),
        ],
      ),
    );
  }
}

class Event {
  final String title;

  Event({required this.title});
}
