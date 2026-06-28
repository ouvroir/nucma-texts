package ca.nucma.oxygen;

import java.util.List;
import java.util.Set;

import ro.sync.contentcompletion.xml.Context;
import ro.sync.ecss.extensions.api.link.CannotRecognizeIDException;
import ro.sync.ecss.extensions.api.link.IDTypeIdentifier;
import ro.sync.ecss.extensions.api.link.IDTypeRecognizer;
import ro.sync.ecss.extensions.tei.id.TEIP5IDTypeRecognizer;

/**
 * ID recognizer of the NUCMA framework: the TEI P5 recognizer, which handles {@code @xml:id}
 * declarations and {@code @target} references, extended to {@code @ref}, {@code @corresp} and
 * {@code @who}. Their values are passed to the TEI recognizer as if they were {@code @target}
 * values, so {@code #identifier} references are resolved the same way: Cmd/Ctrl+click and
 * Search Declarations find the declaration in the main files (registers of meta/, entries).
 */
public class NucmaIDTypeRecognizer extends IDTypeRecognizer {

  /** Attributes whose {@code #identifier} values are references, like {@code @target}. */
  private static final Set<String> REFERENCE_ATTRIBUTES = Set.of("ref", "corresp", "who");

  /** The TEI P5 recognizer, which does the actual work. */
  private final TEIP5IDTypeRecognizer tei = new TEIP5IDTypeRecognizer();

  /**
   * Name under which the attribute is passed to the TEI recognizer.
   *
   * @param attrName local name of the attribute.
   * @return "target" for a reference attribute, the name unchanged otherwise.
   */
  private static String asTeiAttribute(String attrName) {
    return REFERENCE_ATTRIBUTES.contains(attrName) ? "target" : attrName;
  }

  @Override
  public List<IDTypeIdentifier> detectIDType(String systemID, Context context, String attrName,
      String attrNs, String attributeValue, int offset) throws CannotRecognizeIDException {
    return tei.detectIDType(systemID, context, asTeiAttribute(attrName), attrNs, attributeValue,
        offset);
  }

  @Override
  public int[] locateIDType(String systemID, Context context, String attrName, String attrNs,
      String attributeValue, IDTypeIdentifier idIdentifier, short mode) {
    return tei.locateIDType(systemID, context, asTeiAttribute(attrName), attrNs, attributeValue,
        idIdentifier, mode);
  }

  @Override
  public boolean isDefaultIDTypeRecognitionAvailable() {
    return tei.isDefaultIDTypeRecognitionAvailable();
  }

  @Override
  public boolean isIDTypeRecognitionAvailable() {
    return tei.isIDTypeRecognitionAvailable();
  }
}
