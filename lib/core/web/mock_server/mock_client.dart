import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/testing.dart';

part 'response_body.dart';

/// Http mock client for testing purpose.
MockClient mockClient() {
  return MockClient(
    (request) async {
      int delayInMs = 0;
      if (request.url.path.contains('products')) {
        delayInMs = 1000;
      } else if (request.url.path.contains('orders')) {
        delayInMs = 1500;
      } else if (request.url.path.contains('order/order-details')) {
        delayInMs = 2000;
      }
      log('Waiting time for response...... $delayInMs ms for the request => ${request.url.path}');
      await Future.delayed(Duration(milliseconds: delayInMs));

      final headerToken = request.headers[HttpHeaders.authorizationHeader];

      final path = request.url.path;

      if (path.contains('products')) {
        return Response(_productsResponseBody, 200, request: request);
      } else if (path.contains('orders')) {
        return Response(_ordersResponseBody, 200, request: request);
      } else if (path.contains('order/order-details')) {
        return Response(_orderDetailsResponseBody, 200, request: request);
      }
      return Response('Success', 200, request: request);
    },
  );
}
