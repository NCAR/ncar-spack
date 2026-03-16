# Publishing Changes
Finally, assuming all goes well to this point and testing was a success, you can publish the changes from the *build* environment to the *public* environment. A helper script should handle all of this for you.

:rotating_light: **You should rarely, if ever, need to manually make changes to the public environment!** :rotating_light:

All published changes get committed and pushed to a GitHub repo (if this is a production deployment) called `spack-<cluster>` . This repo is publicly visible and can be used by the community to report bugs and request new packages. Thus, the publish script expects one argument - a commit message.

```
bin/publish "Installed latest emacs for benkirk in #4"
```

The `publish` script will describe all of the changes it makes, including package installs, **spack.yaml** changes,  refreshing the module tree, and postprocessing.

#### What if something went wrong?

Spack is finnicky and it is rather easy to get in a pickle, but *most* situations are recoverable if addressed early. If you are unsure about what to do, please ask for help in our **hpc-ucar #spack** Slack channel!

## Updating a cluster definition with production changes

TODO: document when and how to do this
