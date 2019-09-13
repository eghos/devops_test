<<<<<<< HEAD
# DevOps Test

#APPLICATION

The application is a simple application, which I currently use to play arounf in my Kubernetes cluster.
It basically takes a number(index) as an input and does some Fibonacci calculation with it.

This is a complete stack app, which consist of a reactJS frontend, the backend - Express server, and a nodeJS Worker. It also has a postgresql database and a redis cache.

## How it works
you enter a number, and the server sends the number to a redis cache as well as the postgresql database. The essence of redis is store the indices and calculated values as key value pairs. The worker basically fetches the number, does the calculation and sends the result back to redis, while the database maintains a permanent list of indices that have been entered.

#THE COMPONENTS
## Load Balancer
I have used an application load balancer in front of the application. The load balancer is using path-based routing, and using listener rules to route traffic to target groups. There are two target grooups - the frontend and api(backend). By default the load balancer would load the frontend as expected, but when number is entered and submiited(post), or calculated value retrieved(get),the traffic is captured in the backend as "/api" as seen in Fib.js in the Server.

## Security Groups
I am using only two security groups - the "devops_sg" which I have made open (ingress and egress) for the purpose of the exercise, one of the reasons being that the instances need to be updated during bootstrap and so needs access to the internet. And also the default security group where I placed the Postgresql and Redis instances. It is also open so they can receive traffic from the Server and Worker

## The Ports
The ALB is listening on port 80, but routes traffic to target groups on port 3000 (frontend) and 5000 (backend). The instances route traffic to Redis and Postgresql on ports 6379 and 5432 respectively.

## Frontend
t2-micro instance, boostrapped to install nodeJS, nginx, git and clone the project repo, run npm install to install dependencies, run npm build to build the project, and then copy the build file to nginx root dir, where the pages are served from. At this stage, we do not acttually need the node modules and other irrelevant files, but they are there anyway, in real world, I would clean up unnecessary files.

## Worker and Server
t2-micro instances, nodeJS installed, project pulled , dependencies installed and node started.

## Redis and Postgresql
Both were created manually in AWS and endpoints and other credentials  used in keys.js files in both Server and Worker projects. The code references this file to get the environment variables to access both servers

#Network
I have used my existing VPC and subnets

#REDUCING COMPLEXITY
I wanted to use chef-solo along with this, but I thought it would be pointless since it will achieve the same result if I bootstrap the installations. The idea is to reduce complexity and maximise time while achieveing the same result. But in real world, Chef or any other config management tool might suffice to maintain consistency across the board.

#DEPLOYMENT
##Part Deployment
Just run the fullstack.tf file. That is enough to load the frontend using the load balancer DNS name
##Full deployment
Create Redis and Posgresql instances , and use the credentials in the keys.js files in Server and Worker projects


# WHAT COULD BE DONE BETTER IN DEV
In real world, a lot could be done differently, but here are some of the things I would do:

-- Use certificates
-- Clean up files in the frontend
-— Separate variables out - no hardcoding 
—- Each of server, worker, frontend and alb should perhaps have their security groups, which are used as source in ingress rules 
—- Separate repos for the worker, server, frontend
—- Terraform structured properly so modules are reused 
—- Config management tool
-- Put instances in private subnet and reach the internet via NAT
-- Use bastion to ssh to them
—- Secured NACL
-- ASG & Lifecycle hooks

------I guess many more 

#CONLUSION
This is the app that is deployed to my Kubernetes cluster in GCP, actually adapted it a bit to suit this test. 





=======
# devops_test
Repository for the devops test app
>>>>>>> e13ca676e79680bc59643fe810be674aef1d22a6
