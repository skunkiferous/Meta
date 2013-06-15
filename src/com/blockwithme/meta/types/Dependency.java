/**
 *
 */
package com.blockwithme.meta.types;

import com.blockwithme.meta.Definition;

/**
 * A dependency defines the requirement that a bundle as about the presence of
 * other bundles.
 *
 * TODO: What does it mean to be an optional dependency?
 * TODO: Do we need a scope?
 *
 * @author monster
 */
public interface Dependency extends Definition<Dependency>, Bundled<Dependency> {
    /** The minimum version of the required bundle. */
    int minimumVersion();

    /** The maximum version of the required bundle. */
    int maximumVersion();

    /** Is this dependency optional? */
    boolean optional();

    /** (Mutable) Is this dependency currently use? */
    boolean actual();
}
