# krm-fn-kustomize

[KRM](https://github.com/kubernetes-sigs/kustomize/blob/master/cmd/config/docs/api-conventions/functions-spec.md) function
to run [Kustomize](https://kustomize.io/).

## Usage

By default this function will build the Kustomization and output it to `build.yaml`.

```shell
kpt fn eval --image ghcr.io/jashandeep-sohi/krm-fn-kustomize
```

You can override the kustomize command using the `cmd` option:

```shell
kpt fn eval --image ghcr.io/jashandeep-sohi/krm-fn-kustomize -- cmd='kustomize build --output test.yaml'
```

Or declaratively:

```yaml
apiVersion: kpt.dev/v1
kind: Kptfile
metadata:
  name: example
  annotations:
    config.kubernetes.io/local-config: "true"
pipeline:
  mutators:

  # This will build the Kustomization and output it to build.yaml
  - image: ghcr.io/jashandeep-sohi/krm-fn-kustomize

  # Override the command
  - image: ghcr.io/jashandeep-sohi/krm-fn-kustomize
    configMap:
      cmd: kustomize build --output test.yaml
```
