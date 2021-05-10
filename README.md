# covid19

Repository to dashboard about Covid19 data from South America and serverless function to update data.

## IBM Functions

- `Dockerfile.update`
- `exec`
- `read_update_data.R`
- `.Renviron`

```
# Docker build
docker build -t th1460/update-covid -f Dockerfile.update .

# Docker push
docker push th1460/update-covid

# Package files
zip -r update_covid.zip exec read_update_data.R .Renviron

# Create function
ibmcloud fn action create update-covid19 update_covid.zip --docker th1460/update-covid --web true
```

## Cloud foundry

- `Dockerfile.app`
- `app.R`
- `manifest.yml`

```
# Docker build
docker build -t th1460/dash-covid -f Dockerfile.app .

# Docker push
docker push th1460/dash-covid

# Deploy shiny
ibmcloud cf push dash-covid --docker-image th1460/dash-covid -k 2G
```

## CI/CD

Reference to CI/CD used here: 

https://github.com/marketplace/actions/deploy-to-ibm-cloud-foundry
