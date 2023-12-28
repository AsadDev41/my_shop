import 'package:flutter/material.dart';
import 'package:my_shop/providers/product.dart';
import 'package:my_shop/providers/products.dart';
import 'package:provider/provider.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = 'edit_product';
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EdirProductScreenState();
}

class _EdirProductScreenState extends State<EditProductScreen> {
  final priceFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();
  final imageUrlController = TextEditingController();
  final imageUrlFocusNode = FocusNode();
  final form = GlobalKey<FormState>();
  var editProduct =
      Product(id: null, title: '', description: '', price: 0, imageUrl: '');

  var inItvalues = {
    'title': '',
    'description': '',
    'price': '',
    'imageUrl': '',
  };

  var isInit = true;
  var isLoading = false;

  @override
  void initState() {
    imageUrlFocusNode.addListener(updateUrl);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (isInit) {
      final productId = ModalRoute.of(context)!.settings.arguments as String?;
      if (productId != null) {
        final editProduct =
            Provider.of<Products>(context, listen: false).findById(productId);
        inItvalues = {
          'title': editProduct.title,
          'description': editProduct.description,
          'price': editProduct.price.toString(),
          // 'imageUrl': editProduct.imageUrl,
          'imageUrl': '',
        };
        imageUrlController.text = editProduct.imageUrl;
      }
    }
    isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    imageUrlFocusNode.removeListener(updateUrl);
    priceFocusNode.dispose();
    descriptionFocusNode.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  void updateUrl() {
    if (!imageUrlFocusNode.hasFocus) {
      if (!imageUrlController.text.startsWith('http') &&
          !imageUrlController.text.startsWith('https')) return;
    }

    setState(() {});
  }

  Future<void> saveform() async {
    final isvalid = form.currentState!.validate();
    if (!isvalid) {
      return;
    }
    form.currentState!.save();
    setState(() {
      isLoading = true;
    });
    if (editProduct.id != null) {
      Provider.of<Products>(context, listen: false)
          .updateProduct(editProduct.id!, editProduct);
      setState(() {
        isLoading = false;
      });
      Navigator.of(context).pop();
    } else {
      try {
        await Provider.of<Products>(context, listen: false)
            .addProduct(editProduct);
      } catch (error) {
        await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text(
                    'An Error Occured',
                  ),
                  content: Text('SomeThing went Wrong.!'),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Okay'))
                  ],
                ));
      } finally {
        setState(() {
          isLoading = false;
        });
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        actions: [
          IconButton(
            onPressed: saveform,
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: EdgeInsets.all(8),
              child: Form(
                  key: form,
                  child: ListView(
                    children: [
                      TextFormField(
                        initialValue: inItvalues['title'],
                        decoration: InputDecoration(labelText: 'Title'),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(priceFocusNode);
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter the title';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          editProduct = Product(
                            title: value.toString(),
                            price: editProduct.price,
                            description: editProduct.description,
                            imageUrl: editProduct.imageUrl,
                            id: editProduct.id,
                            isFavorite: editProduct.isFavorite,
                          );
                        },
                      ),
                      TextFormField(
                        initialValue: inItvalues['price'],
                        decoration: InputDecoration(labelText: 'Price'),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        focusNode: priceFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(descriptionFocusNode);
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter The price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.tryParse(value)! <= 0) {
                            return 'Please Enter the number greater than zero';
                          }
                        },
                        onSaved: (value) {
                          editProduct = Product(
                            title: editProduct.title,
                            price: double.parse(value!),
                            description: editProduct.description,
                            imageUrl: editProduct.imageUrl,
                            id: editProduct.id,
                            isFavorite: editProduct.isFavorite,
                          );
                        },
                      ),
                      TextFormField(
                        initialValue: inItvalues['description'],
                        decoration: InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        focusNode: descriptionFocusNode,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter the Description';
                          }
                          if (value.length < 10) {
                            return 'description should be at least 10 characters';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          editProduct = Product(
                            title: editProduct.title,
                            price: editProduct.price,
                            description: value.toString(),
                            imageUrl: editProduct.imageUrl,
                            id: editProduct.id,
                            isFavorite: editProduct.isFavorite,
                          );
                        },
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            margin: EdgeInsets.only(top: 8, right: 10),
                            decoration: BoxDecoration(
                                border:
                                    Border.all(width: 1, color: Colors.grey)),
                            child: imageUrlController.text.isEmpty
                                ? Text('Enter a URL')
                                : FittedBox(
                                    child:
                                        Image.network(imageUrlController.text),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(labelText: 'Image'),
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              controller: imageUrlController,
                              focusNode: imageUrlFocusNode,
                              onFieldSubmitted: (_) {
                                saveform();
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter image URL';
                                }
                                if (!value.startsWith('http') &&
                                    !value.startsWith('https')) {
                                  return 'Please enter a valid URL';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                editProduct = Product(
                                  title: editProduct.title,
                                  price: editProduct.price,
                                  description: editProduct.description,
                                  imageUrl: value.toString(),
                                  id: editProduct.id,
                                  isFavorite: editProduct.isFavorite,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
            ),
    );
  }
}
