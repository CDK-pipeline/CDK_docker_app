from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World, from FastAPI! Test! this is working!"}

@app.get("/new-endpoint")
async def new_endpoint():
    return {"message": "This is a new endpoint"}