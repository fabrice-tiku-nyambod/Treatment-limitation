# ---------------------------------------------------------------------------
# 10b_palette_search.R
# Search for a 4-step ordinal ramp clearing all four gates on a WHITE surface.
#   normal-vision dE >= 15, CVD dE >= 8, contrast >= 2:1, monotonic lightness
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({ library(colorspace) })

srgb2lin <- function(c) ifelse(c <= 0.04045, c/12.92, ((c + 0.055)/1.055)^2.4)
hex2oklab <- function(hex) {
  rgb <- t(col2rgb(hex))/255; lin <- srgb2lin(rgb)
  l <- 0.4122214708*lin[,1] + 0.5363325363*lin[,2] + 0.0514459929*lin[,3]
  m <- 0.2119034982*lin[,1] + 0.6806995451*lin[,2] + 0.1073969566*lin[,3]
  s <- 0.0883024619*lin[,1] + 0.2817188376*lin[,2] + 0.6299787005*lin[,3]
  l_ <- l^(1/3); m_ <- m^(1/3); s_ <- s^(1/3)
  cbind(L = .2104542553*l_ + .7936177850*m_ - .0040720468*s_,
        a = 1.9779984951*l_ - 2.4285922050*m_ + .4505937099*s_,
        b = .0259040371*l_ + .7827717662*m_ - .8086757660*s_)
}
dE <- function(a, b) 100*sqrt(rowSums((hex2oklab(a) - hex2oklab(b))^2))
relL <- function(hex) { rgb <- t(col2rgb(hex))/255; lin <- srgb2lin(rgb)
  .2126*lin[,1] + .7152*lin[,2] + .0722*lin[,3] }
contrast <- function(hex) (pmax(relL(hex), 1) + .05) / (pmin(relL(hex), 1) + .05)

score <- function(pal) {
  n <- c(); cvd <- c()
  for (i in 1:(length(pal)-1)) {
    n   <- c(n, dE(pal[i], pal[i+1]))
    cvd <- c(cvd, dE(deutan(pal[i]), deutan(pal[i+1])),
                  dE(protan(pal[i]), protan(pal[i+1])),
                  dE(tritan(pal[i]), tritan(pal[i+1])))
  }
  Ls <- hex2oklab(pal)[, "L"]
  list(n = min(n), cvd = min(cvd), cr = min(contrast(pal)),
       mono = all(diff(Ls) < 0) || all(diff(Ls) > 0))
}

cands <- list()
for (opt in c("viridis","mako","rocket","cividis")) {
  for (b in seq(0, .35, .05)) for (e in seq(.70, 1, .05)) {
    p <- rev(hcl.colors(4, palette = switch(opt, viridis="Viridis", mako="Mako",
                                            rocket="Rocket", cividis="Cividis")))
    p <- rev(grDevices::hcl.colors(100, palette = switch(opt, viridis="Viridis",
              mako="Mako", rocket="Rocket", cividis="Cividis"))[
              round(seq(b*99+1, e*99+1, length.out = 4))])
    cands[[length(cands)+1]] <- list(name = sprintf("%s [%.2f,%.2f]", opt, b, e), pal = p)
  }
}

res <- data.frame()
for (c_ in cands) {
  s <- score(c_$pal)
  res <- rbind(res, data.frame(name = c_$name, pal = paste(c_$pal, collapse = ","),
                               normal = round(s$n,1), cvd = round(s$cvd,1),
                               contrast = round(s$cr,2), mono = s$mono))
}
pass <- subset(res, normal >= 15 & cvd >= 8 & contrast >= 2 & mono)
pass <- pass[order(-pass$cvd, -pass$normal), ]
cat(sprintf("candidates tested: %d   passing all four gates: %d\n\n",
            nrow(res), nrow(pass)))
print(head(pass, 12), row.names = FALSE)
