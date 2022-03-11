library(glue)
library(tidyverse)

#Go into the raw models folder and grab all the model names
setwd("models/")
models <- list.files() %>% 
  #remove the .mod. That way we just have the model name (makes it easier to add to it)
  str_remove(".mod")

#For each model, go into it, add the necessary code for a pitarg shock, and then save it in pitarg_models_raw
# See sed documentation in Notes.docx
for (model in models) {
  system(glue("sed -e '/Modelbase Variables *\\//a pitarg' -e '0,/varexo/{s/varexo/varexo shk/}' -e \"s|Modelbase Variables in Terms of Original Model Variables|Modelbase Variables in Terms of Original Model Variables\\npitarg = pitarg(-1) - shk;|\" -e '/shocks;/a var shk;\\nstderr 0.25;' -e 's/*interest_/*interest_ -(cofintinf0+cofintinfb1+cofintinfb2+cofintinfb3+cofintinfb4+cofintinff1+cofintinff2+cofintinff3+cofintinff4)*pitarg/' -e '$astoch_simul(irf=60, nograph);' -e '$asave(\"[model]_pitarg.mat\")' [model].mod > ../pitarg_models_raw/[model]_pitarg.mod",
              .open = "[",
              .close = ']'))
}

#Go back up to the home directory
setwd("..")

# copy all the pitarg adjusted models into a folder from which I will run them
system("cp -r pitarg_models_raw/* pitarg_models/")

# #Testing
# model=models[1]
# setwd("testing-station/")
# 
# system(glue("sed -e '$astoch_simul(irf=60, nograph)' -e '$asave(\"[model]_pitarg.mat\")' [model].mod > [model]_pitarg.mod",
#        .open = "[",
#        .close = ']'))
#             
# # 
# # system(glue("sed -e '/Modelbase Variables/a pitarg;' NK_CGG99.mod > NK_CGG99_pitarg.mod",
# #             .open = "[",
# #             .close = ']'))
# # 
# # system(glue("sed -e '0,/Modelbase Variables/s/Modelbase Variables/a pitarg/'  NK_CGG99.mod > NK_CGG99_pitarg.mod",
# #             .open = "[",
# #             .close = ']'))
# # 
# # system("sed -e '/Modelbase Variables *\\//a pitarg' -e '0,/varexo/{s/varexo/varexo shk/}' -e \"s|Modelbase Variables in Terms of Original Model Variables|Modelbase Variables in Terms of Original Model Variables\\npitarg = pitarg(-1) - shk;|\" -e '/shocks;/a var shk;\\nstderr 0.25;' -e 's/*interest_/*interest_ -(cofintinf0+cofintinfb1+cofintinfb2+cofintinfb3+cofintinfb4+cofintinff1+cofintinff2+cofintinff3+cofintinff4)*pitarg/' -e \"s|//stoch_simul|stoch_simul|\" -e \"s|irf = 0|irf = 40|\" -e '$asave(\"[model]_pitarg.mat\")' NK_CGG99.mod > NK_CGG99_pitarg.mod")
# # 
# # '0,/Matched Keyword/s//New Inserted Line\n&/'
# # #system("cp -r pitarg_models_raw/* pitarg_models/")
# 
# 
#             
# 
