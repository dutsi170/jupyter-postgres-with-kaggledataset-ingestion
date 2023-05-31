
# What will we need?
In order to provision a microservice application, containing a JupyterLab environment, a Postgres Database (where they can communicate each other), with the data coming from Kaggle API and being ingested in the database, first we need to make sure we have Docker installed (the official website https://docs.docker.com/engine/install brings the step-by-step of installing it accordingly to your OS) and only then follow these 5 steps:

  1. Take one of the Jupyter's docker image available at https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html as base image (we are going to use the jupyter/base-notebook image because it's the leanest one and for our purposes it will fit well) and build our custom Jupyter image through a Dockerfile (since we are going to use a Kaggle dataset downloaded in zip format we will need to do some installations);
  2. Once the Jupyter part is ready, we need to pull a Postgres image too;
  3. The images are like the classes and the containers the instances (if we reference to OOP) so we need to create the 'instances' running the images;
  4. As we are going to use plain docker (and not the compose one), the containers are not aware of each other yet, so a Docker network will be needed;
  5. The final step is doing some python code using both pandas and sqlalchemy libs, where we will ingest an aggregated table into postgres database;

## 1. Creating our custom Jupyter image
To create our Jupyter-based image, first we need to pull it through `docker pull jupyter/base-notebook` on our terminal. Once downloaded, we can create our [Dockerfile](Dockerfile) and then build the image in this Dockerfile folder, doing "`docker build -t myjupyterimage:v1 .`" (don't forget the trailling dot, because it references the Dockerfile file in the current directory).

## 2. Pulling Postgres image from Docker Hub
Pulling a docker image is always the same, whether it comes from the official [Docker Hub](https://hub.docker.com/) or another one like [Bitnami](https://bitnami.com/stacks/containers). What you will need is just a simple `docker pull <desired_image_tag>`, and in our case, `docker pull postgres`.

## 3. Running the images to create the containers
### Running the Jupyter part:
```bash
docker run \
  --name myjupytercontainer \
  -p 8888:8888 \
  -v ${PWD}:/home/jovyan/work \
  -e KAGGLE_USERNAME=yourkaggleusername \
  -e KAGGLE_KEY=yourkagglekey \
  myjupyterimage:v1
```
### Running the Postgres part (on another terminal):
```bash
docker run -d \
  --name mypostgrescontainer \
  -p 5432:5432 \
  -v postgresvol:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=<supersecret> \
  postgres
```
## 4. Creating a Docker Network 
Create a docker network allows containers to be aware of each other, and exchange content though TCP/UDP protocols, so to this, we need to:

1. Create a docker network (with the default bridge option):\
`docker network create jupyter-postgres-network`;
2. Connect the Jupyter container to the network:\
`docker network connect jupyter-postgres-network myjupytercontainer`
3. Connect the Postgres container to the network:\
`docker network connect jupyter-postgres-network mypostgrescontainer`

## 5. Doing some Python Code
The final part of this project, is entering on JupyterLab environment (whose local with its token will be shown by the `docker logs myjupytercontainer 2>&1 | grep 127.0.0.1:8888 | tail -1` command), and using the [IngestingData](IngestingData.ipynb) notebook where we will load the required packages, download the **arnabchaki/data-science-salaries-2023** dataset, insert the whole dataset into a pandas dataframe, and then do some calculations, to create a top 5 average salary by year and load into the database. Last but not least, we will fetch the results from this created table, in order to check if all is running properly.