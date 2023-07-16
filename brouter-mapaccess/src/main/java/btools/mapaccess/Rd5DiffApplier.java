/**
 * Apply all rd5 diff-files
 *
 * @author vcoppe
 */
package btools.mapaccess;

import java.io.File;
import java.util.Arrays;
import java.util.Comparator;

import btools.util.ProgressListener;

final public class Rd5DiffApplier implements ProgressListener
{
  public static void main(String[] args) throws Exception
  {
    applyDiffs(new File(args[0]), new File(args[1]), new File(args[2]));
  }

  /**
   * Apply diffs for all RD5 files
   */
  public static void applyDiffs(File segmentsDir, File diffDir, File outDir) throws Exception
  {
    Rd5DiffApplier progress = new Rd5DiffApplier();

    outDir.mkdir();

    File[] fileSegments = segmentsDir.listFiles();
    Arrays.sort(fileSegments, Comparator.comparing(File::getName));

    for (File fs : fileSegments)
    {
      String name = fs.getName();
      if (!name.endsWith(".rd5"))
      {
        continue;
      }

      File newSegment = new File(outDir, name);
      newSegment.createNewFile();
      Rd5DiffTool.copyFile(fs, newSegment, progress);
      newSegment.setLastModified(fs.lastModified());

      String basename = name.substring(0, name.length() - 4);
      File segmentDiffDir = new File(diffDir, basename);
      if (segmentDiffDir.isDirectory())
      {
        File[] segmentDiffFiles = segmentDiffDir.listFiles();
        Arrays.sort(segmentDiffFiles, Comparator.comparingLong(File::lastModified));

        for (File segmentDiff : segmentDiffFiles)
        {
          String diffName = segmentDiff.getName();
          if (!diffName.endsWith(".df5"))
          {
            continue;
          }
          if (segmentDiff.lastModified() <= fs.lastModified())
          {
            continue; // diff is older than segment
          }
          if (segmentDiff.length() == 0L)
          {
            continue; // avoid changing date for empty diff
          }

          System.out.println("Applying diff " + segmentDiff.getName() + " to segment: " + name);

          File tmpSegment = new File(outDir, "tmp.rd5");
          tmpSegment.createNewFile();

          Rd5DiffTool.recoverFromDelta(newSegment, segmentDiff, tmpSegment, progress);

          newSegment.delete();

          tmpSegment.renameTo(new File(outDir, name));
          newSegment = new File(outDir, name);
          newSegment.setLastModified(segmentDiff.lastModified());
        }
      }
    }
  }

  @Override
  public void updateProgress(String task, int progress) { }

  public boolean isCanceled()
  {
    return false;
  }
}
