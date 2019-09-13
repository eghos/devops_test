# DevOps Test

#APPLICATION

The application is a simple application, which I currently use to play arounf in my Kubernetes cluster.
It basically takes a number(index) as an input and calculates something out of it.

This is a complete stack app, which consist of a reactJS frontend, the backend express server, and a nodeJS worker. It also has a postgresql database and a redis cache.

## How it works
you enter a number, and the server sends the number to a redis cache as well as the postgresql database. The essence of redis is store the indices and calculated values as key value pairs. So that the worker fetches the number, does the calculation and sends the result back to redis, while the database maintains a permanent list of indices that have been entered.

#THE COMPONENTS
## Load Balancer
I have used an application load balancer in front of the application. The load balancer is using path-based routing, and using listener rules to route traffic to target groups. There are two target grooups - the frontend and api(backend). By default the load balancer would load the frontend as expected, but when number is entered and submiited , as expected the path changes and the new traffic is routed to the backend for processing. 

## Security Groups
I am using only two security groups - the "devops_sg" which I have made open (ingress and egress) for the purpose of the exercise, one of the reasons being that the instances need to be updated during bootsrap and so needs access to the internet. And also the default security group where I placed the PostgreSql and Redis instances. It is also open so they can receive traffic from the Server and Worker

## The Ports
The ALB is listening on port 80, but routes traffic to target groups on port 3000 and 5000. The instances route traffic to Redis and Postgresql on ports 6379 and 5432 respectively.

## Frontend
t2-micro instance, boostrapped to install nodeJS, nginx, git and clone the project repo, run install to install dependencies, run build to build the project, and then copy the build file to nginx root dir, where the pages are served from. At this stage, we do not acttually need the node modules and other irrelevant file, but they are there anyway, in real world, I would clean up unnecessary files.

## Worker and Server
t2-micro instances, nodeJS installed, project pulled , dependencies installed and node started.

## Redis and Postgresql
Both were created manually in AWS and endpoints used in the keys.js files in both Server and Worker projects. The code references this file to get the environment variables to access both servers

#REDUCING COMPLEXITY
I wanted to use chef-solo along with this, but I thought it would be pointless since it will achieve the same result if I bootstrap the installations. The idea is to reduce complexity and maximise time while achieveing the same result. But in real world, Chef or any other config management tool might suffice to maintain consistency across the board.

#DEPLOYMENT
Just run the terraform files in this order - frontend.tf, server.tf, worker.tf, alb.tf
The reason being that frontend.tf creates the frontend instance as well as the other components that the project depend on e.g security group. It is important that the instances exist beore alb.tf is run, so that it finds the instances to add to target groups. You may need to tweak the security group and instance ids in alb.tf 

# WHAT COULD BE DONE BETTER
In real world, a lot could be done differently, but here are some of the things I would do in real world
-- Certificates
-- Clean up files in the frontend
-— Separate variables out - no hardcoding 
—- Each of server, worker, frontend and alb should perhaps have their security groups, which are used as source in ingress rules 
—- Healthcheck block in alb listener
—- Separate repos for the worker, server, frontend
—- Terraform structured properly so modules are reused 
—- For big projects, use config management tool
-- The instances in private subnet and reaching the internet via NAT
—- Secured NACL
—- Point terraform to the file where the public key is, not hardcoded
-- ASG & Lifecycle hooks

------I guess many more 

#CONLUSION
This is the app that I have deployed to my Kubernetes cluster in GCP, I actually adapted it a bit to suit this test. 




