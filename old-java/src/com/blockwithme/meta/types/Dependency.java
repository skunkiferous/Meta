/**
 *
 */
package com.blockwithme.meta.types;

import com.tinkerpop.frames.Property;
import com.tinkerpop.frames.modules.typedgraph.TypeValue;

/**
 * A dependency defines the requirement that a bundle as about the presence of
 * other bundles.
 *
 * TODO: What does it mean to be an optional dependency?
 * TODO: Do we need a scope?
 *
 * @author monster
 */
@TypeValue("Dependency")
public interface Dependency extends Bundled {
    /** The minimum version of the required bundle. */
    @Property("minimumVersion")
    int getMinimumVersion();

    /** The minimum version of the required bundle. */
    @Property("minimumVersion")
    void setMinimumVersion(final int minimumVersion);

    /** The maximum version of the required bundle. */
    @Property("maximumVersion")
    int getMaximumVersion();

    /** The maximum version of the required bundle. */
    @Property("maximumVersion")
    void setMaximumVersion(final int maximumVersion);

    /** Is this dependency optional? */
    @Property("optional")
    boolean isOptional();

    /** Is this dependency optional? */
    @Property("optional")
    void setOptional(final boolean optional);

    /** (Mutable) Is this dependency currently use? */
    @Property("actual")
    boolean isActual();

    /** (Mutable) Is this dependency currently use? */
    @Property("actual")
    void setActual(final boolean actual);
}
