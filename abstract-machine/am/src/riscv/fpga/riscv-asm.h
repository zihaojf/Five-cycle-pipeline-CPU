#define FUNC_TYPE(X) .type X,@function
#define FUNC_SIZE(X) .size X,.-X

#define FUNC_BEGIN(X) \
  .globl X; \
  FUNC_TYPE(X); \
X:

#define FUNC_END(X) \
  FUNC_SIZE(X)

#define FUNC_ALIAS(X,Y) \
  .globl X; \
  X = Y
