# Desktop Installation Module

This module handles the desktop environment branding, wallpaper selection, and UI configuration for SquirrelWorks workspace images.

## Customizing Wallpapers

The wallpaper system is designed to be modular and easily expandable. Wallpapers are applied by the `desktop/install.sh` script, which calls `desktop/set_wallpaper.sh` based on a "theme" argument passed from the `Dockerfile`.

### How to Add a New Wallpaper for a New Image

If you are creating a new workspace image (e.g., `kali-linux`) and want to add a custom background:

1. **Add the Image File:**
   Place your new background image (e.g., `kali_bg.png`) into the shared resources directory:
   `src/ubuntu/resources/images/`

2. **Update the Wallpaper Script:**
   Edit `src/ubuntu/install/desktop/set_wallpaper.sh`. Add your new theme name to the `case` statement, mapping it to your new image file.
   ```bash
   case "$THEME" in
       remnux) SOURCE_IMG="${REPO_RESOURCES}/remnux_bg.png" ;;
       noble)  SOURCE_IMG="${REPO_RESOURCES}/noble_numbat_bg.png" ;;
       kali)   SOURCE_IMG="${REPO_RESOURCES}/kali_bg.png" ;; # Add this line
       *) log "Unknown theme: $THEME"; exit 1 ;;
   esac
   ```

3. **Update the Target Dockerfile:**
   In your new image's `Dockerfile` (e.g., `images/kali-linux/Dockerfile`), locate the execution loop for the `SCRIPTS` array. Ensure it passes your new theme argument when it encounters `desktop/install.sh`:
   ```dockerfile
       # Execution Loop
       for SCRIPT in "${SCRIPTS[@]}"; do 
         echo ">>> Executing Module: ${SCRIPT}"; 
         if [[ "${SCRIPT}" == *"desktop/install.sh" ]]; then 
           bash "${INST_DIR}${SCRIPT}" kali; 
         else 
           bash "${INST_DIR}${SCRIPT}"; 
         fi || { exit 1; }; 
       done; 
   ```

The `install.sh` script defaults to the `noble` theme if no argument is provided.
