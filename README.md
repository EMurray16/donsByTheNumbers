# donsByTheNumbers
a shiny app describing AFC Wimbledon's season

## Rgo

donsByTheNumbers uses [Rgo](https://github.com/EMurray16/Rgo) to facilitate an easier transfer of data from [FiveThirtyEight's soccer predictions server](https://github.com/fivethirtyeight/data/tree/master/soccer-spi) to R. This approach is a bit more complicated to implement, especially if you aren't familiar with both R and Go, but has a few advantages:

- Go's handling of http errors is far superior to R's
- Go's ability to loop through an entire file of data and quickly eliminate unnecesasry rows while simultaneously adding detail to the rows it keeps is better than R's
- With the exception of plotting and data visualization, doing literally any task in Go is less stressful than doing it in R. Feel free to [@ me if you disagree](https://twitter.com/overthinkDCI)

### Building the C shared library for R

The R code for the app assumes the Go program in the `fte` folder has been compiled to a C shared library. The following command builds the library from the command line:

```
go build -o getFTE.so -buildmode=c-shared
```

