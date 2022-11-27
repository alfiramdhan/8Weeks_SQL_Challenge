## Introduction

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

Full description: [Case Study #2 - Pizza Runner ](https://8weeksqlchallenge.com/case-study-2/)

1. runners table shows the registration_date for each new runner :
- runner_id
- registration_date

2. customer_orders table are captured in the customer_orders table with 1 row for each individual pizza that is part of the order.
- The pizza_id relates to the type of pizza which was ordered whilst the exclusions are
- the ingredient_id values which should be removed from the pizza and the extras are
- the ingredient_id values which need to be added to the pizza.
- order_id
- customer_id
- pizza_id
- exclusions
- extras
- order_time

3. runner_orders table shows :
- order_id
- runner_id
- pickup_time
- distance
- duration
- cancellation

4. pizza_names table
- pizza_id
- pizza_name

5. pizza_recipes
- pizza_id
- toppings

6. pizza_toppings
- topping_id
- topping_names


## Case Study Questions

This case study has LOTS of questions - they are broken up by area of focus including:

- Pizza Metrics
- Runner and Customer Experience
- Ingredient Optimisation
- Pricing and Ratings
- Bonus DML Challenges (DML = Data Manipulation Language)

## A. Pizza Metrics

1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

## ANSWER :
