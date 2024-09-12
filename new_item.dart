import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/data/categories.dart';
//import 'package:shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/grocery_item.dart'; //bundle http package content into object named http

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<
      FormState>(); //gain access to form & its widgets like validate and reset
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      //we know it wont be null bc form will be created before we press elevatedButton. validate returns bool
      _formKey.currentState!.save();

      setState(() {
        _isSending = true;
      });

      final url = Uri.https('flutter-prep-5f0b0-default-rtdb.firebaseio.com',
          'shopping-list.json'); //uri built in class that has special methods
      //shopping-list.json is the path , we named it ourself, but .json is required from firebase
      final response = await http.post(
        //await is wait for data is available before executing next lines. then it gets stored into response
        //line above also means responses needs to wait for http code to execute before the data is available. response type is id's by post built in
        url,
        headers: {
          'Content-Type':
              'application/json', //show firebase how data will be formatted
        },
        //body of post - what to send
        body: json.encode(
          {
            // {} to create a map - easy to convert it into json.
            'name': _enteredName, //wrap keys in ''
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
          },
        ),
      );

      print(response.body);
      print(response.statusCode);

      final Map<String, dynamic> resData = jsonDecode(response.body);

      if (!context.mounted) {
        //if context isnt mounted then dont execute below mounted means part of screen
        return;
      }
      Navigator.of(context).pop(GroceryItem(
          id: resData['name'],
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory));

      //Navigator.of.pop(GroceryItem(
      //  id: DateTime.now().toString(),
      // name: _enteredName,
      // quantity: _enteredQuantity,
      // category: _selectedCategory));
      //pop return items are all extracted from .save line above pop works by defining and putting items back into the push in grocery list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Add a new item')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Form(
              //form is for input values. gives access to methods like save, validate, reset
              key:
                  _formKey, //tells form to not rebuild and keep its internal state. it marks the state to validate and save
              child: Column(
                children: [
                  TextFormField(
                    // instead of TextField() to integrate form widget
                    maxLength: 50,
                    decoration: const InputDecoration(label: Text('Name')),
                    validator: (value) {
                      //if error comes. value is value of text formfield

                      if (value == null ||
                          value.isEmpty ||
                          value.trim().length <= 1 ||
                          value.trim().length > 50) {
                        return 'Must be between 1 and 50 characters.';
                      }

                      return null;
                    },
                    onSaved: (value) {
                      _enteredName = value!;
                    },
                  ),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: TextFormField(
                          decoration:
                              const InputDecoration(label: Text('Quantity')),
                          keyboardType: TextInputType.number,
                          initialValue: _enteredQuantity.toString(),
                          validator: (value) {
                            //if error comes. value is value of text formfield

                            if (value == null ||
                                value.isEmpty ||
                                int.tryParse(value) ==
                                    null || //tryparse returns null if value isnt a number
                                int.tryParse(value)! <= 0) {
                              return 'Must be valid, positive number.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredQuantity = int.parse(
                                value!); //parse returns error if no number, tryparse returns null. wont be null bc executed after save
                          }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField //needs expanded for row
                          (
                              value: _selectedCategory,
                              items: [
                                for (final category in categories.entries)
                                  DropdownMenuItem(
                                    value: category.value,
                                    child: Row(children: [
                                      Container(
                                          width: 16,
                                          height: 16,
                                          color: category.value.color),
                                      const SizedBox(width: 6),
                                      Text(category.value.title)
                                    ]),
                                  )
                              ], //entries to convert map to list
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              }),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end, //put buttons on right side
                    children: [
                      TextButton(
                          onPressed: _isSending
                              ? null
                              : () {
                                  _formKey.currentState!.reset();
                                },
                          child: const Text('Reset')),
                      ElevatedButton(
                          onPressed: _isSending ? null : _saveItem, //if isSending is true, _saveitem wont execute
                          child: _isSending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator())
                              : const Text('Add Item'))
                    ],
                  )
                ],
              )),
        ));
  }
}
