package ca.nucma.oxygen;

import ro.sync.ecss.extensions.api.link.IDTypeRecognizer;
import ro.sync.ecss.extensions.tei.TEIP5ExtensionsBundle;

/**
 * Extensions bundle of the NUCMA framework: the TEI P5 bundle, with an ID recognizer that also
 * treats {@code @ref}, {@code @corresp} and {@code @who} as references (see
 * {@link NucmaIDTypeRecognizer}).
 */
public class NucmaExtensionsBundle extends TEIP5ExtensionsBundle {

  @Override
  public IDTypeRecognizer createIDTypeRecognizer() {
    return new NucmaIDTypeRecognizer();
  }

  @Override
  public String getDescription() {
    return "NUCMA extensions bundle (TEI P5, references in @ref, @corresp, @who)";
  }
}
