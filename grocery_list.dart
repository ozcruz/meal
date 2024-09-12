import 'dart:convert';
import 'package:shopping_list/data/categories.dart';
import 'package:flutter/material.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override //override means its already been defined in superclass so stateful
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  //final List<GroceryItem> _groceryItems = []; only if using navigator to get the values
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    //this initialize makes sure loaditems runs even if state<groceryList> is created for first time
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-5f0b0-default-rtdb.firebaseio.com', 'shopping-list.json');

        try { //try and if not then go into catch. great to do with http requests since they throw errors

    final response = await http.get(url);
    
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data';
      });
    }
    if (response.body == 'null') //firebase returns string null, keep in mind backends return it differently
    
    {
      setState((){
      _isLoading = false;
    });
    return;
    }

    //get returns a nested map defined below
    final Map<String, dynamic> listData =
        jsonDecode(response.body); //dynamic value type is different types
    final List<GroceryItem> loadedItems =
        []; //our list of loaded items, what we will be outputting

    for (final item in listData.entries) {
      //entries is values of the list/map
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      //catItem is the Category class in categories data sheet. since we're looking at a specific item via listdata.
      //that means we're looking for when item ['category'] is the same value as cat.item.title. comparing item to all the categorie sentries basicaly
      //then we return it into category (just the title)

      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
        } catch(error){
          setState(() {
        _error = 'Something went wrong!';
      });
        }

   

    

    
  }

  void _addItem() async {
    //final newItem = //only for if we define object via .pop returns
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(
            builder: (ctx) => const NewItem()) //navigate to newitem page
        ); //returns groceryitem type object. waits until it returns to get value for newitem and to execute rest of additem function

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });

//below is if newItem was invoked and defined via .pop returning objects
    //if (newItem == null){return;} //leave additem function if newitem value is null when this executes
    // setState((){
    //  _groceryItems.add(newItem); (reinstated)
    // });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);});
    final url = Uri.https(
        'flutter-prep-5f0b0-default-rtdb.firebaseio.com', 'shopping-list/${item.id}.json'); //inject string to target specific item id

      final response = await http.delete(url);

      if (response.statusCode >= 400) {

        setState(() {
      _groceryItems.insert(index, item);});
      //add error msg. this method adds item back in if the backend fails to delete it too
      }

    
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
        child: Text('No items added yet.')); //center puts things in middle

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color),
            trailing: Text(_groceryItems[index]
                .quantity
                .toString()), //trailing is right aligned
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!)); //center puts things in middle
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Your Groceries'), actions: [
          IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
        ]),
        body: content
        );
  }
}
