
function log_taylor(z)
  local result=z-1.0
  for n=2,100 do
    result = result - ((-1)^n*(z-1)^n)/n
  end
  return result
end

function log_atanh(x)
  local xm = (x-1.)/(x+1.)
  local n = 20
  local result=0.
  for k=0,n do
    result = result + 2./(2.*k+1)*xm^(2*k+1)
  end
--  local residual = ((x-1.)^2)/(2*(2*n+3)*math.abs(x))*math.abs(xm)^(2*n-1)
--  result = result + residual
  return result
end


values = {0.5, 1., 2., 3., 4., 5., 10.}
log = {-0.69314718056, 0, 0.69314718056, 1.09861228867, 1.38629436112, 1.60943791243, 2.302585093}

for i, value in ipairs(values) do
  print(string.format("log(%f)=%f (log_atanh: %f) delta=%f", value, log[i], log_atanh(value), log[i]- log_atanh(value)) )
end
